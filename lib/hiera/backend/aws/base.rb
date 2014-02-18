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

        def aws_region
          @scope["location"] || "eu-west-1"
        end

        def aws_account_number
          @scope["aws_account_number"] ||
            AWS::IAM.new.users.first.arn.split(":")[4]
        end

        attr_reader :scope

        def lookup(key, scope)
          @scope = scope
          if respond_to? key
            send(key)
          else
            # Found no handler for key
            nil
          end
        end
      end
    end
  end
end
