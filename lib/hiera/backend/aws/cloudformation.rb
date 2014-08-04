require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/cloudformation
      class Cloudformation < Base
        def initialize(scope = {})
          super(scope)
          @client = AWS::CloudFormation::Client.new
        end

        # Override default key lookup to implement custom format. Examples:
        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split
          return if args.shift != "cloudformation"
          parameters = Hash[args.map { |t| t.split("=") }]
          stack_name = parameters.fetch("stack")
          output_key = parameters.fetch("output")
          lookup_cfn_output_value(stack_name, output_key)
        end

        private

        def lookup_cfn_output_value(stack_name, output_key)
          found_stacks = @client.describe_stacks(:stack_name => stack_name)[:stacks]
          found_stacks.first[:outputs].select do |output|
            output.fetch(:output_key) == output_key
          end.first.fetch(:output_value)
        end
      end
    end
  end
end
