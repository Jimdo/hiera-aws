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

        def lookup(key, scope)
          if respond_to? key
            @scope = scope
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
