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
          AWS.config.to_hash[:region]
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

        # Inspired by http://devblog.avdi.org/2009/07/14/recursively-symbolize-keys/
        def stringify_keys(hash)
          hash.reduce({}) do |result, (key, value)|
            new_key = case key
                      when Symbol then key.to_s
                      else key
                      end
            new_value = case value
                        when Hash then stringify_keys(value)
                        else value
                        end
            result[new_key] = new_value
            result
          end
        end
      end
    end
  end
end
