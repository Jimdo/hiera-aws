require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/rds
      class CloudFormation < Base
        def initialize(scope = {})
          super(scope)
          @client = AWS::CloudFormation.new
        end

        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split('/', 4)

          return if args.length < 3

          backend_keyword, stack_name, property_keyword, property_argument = args

          return if backend_keyword != "cloudformation"

          stack = @client.stacks[stack_name]

          case property_keyword
          when 'output'
            stack_output(stack, property_argument)
          else
            nil
          end
        end

        private

        def stack_output(stack, output_key)
          selected_outputs = stack.outputs.select do |output|
            output.key == output_key
          end

          selected_outputs.first.value unless selected_outputs.empty?
        end
      end
    end
  end
end
