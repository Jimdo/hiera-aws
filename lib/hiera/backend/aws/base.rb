require "aws-sdk"

class Hiera
  module Backend
    module Aws
      class MissingFactError < StandardError; end

      # Base class for all AWS service classes
      class Base
        def initialize(scope = {})
          @scope = scope
        end

        attr_reader :scope

        def aws_region
          puppet_fact("location") || "eu-west-1"
        end

        def aws_account_number
          puppet_fact("aws_account_number") ||
            AWS::IAM.new.users.first.arn.split(":")[4]
        end

        def lookup(key, scope)
          @scope = scope
          if respond_to? key
            send(key)
          else
            # Found no handler for key
            nil
          end
        end

        def puppet_fact(name)
          fact = scope[name]
          return nil if fact == :undefined
          fact
        end
      end
    end
  end
end
