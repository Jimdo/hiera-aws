require "aws-sdk"

class Hiera
  module Backend
    module Aws
      class NoHandlerError < StandardError; end
      class MissingFactError < StandardError; end

      class Base
        def initialize(scope={})
          @scope = scope
        end

        attr_reader :scope

        def lookup(key, scope)
          if respond_to? key
            @scope = scope
            send(key)
          else
            raise NoHandlerError, "no handler for '#{key}' found."
          end
        end
      end
    end
  end
end
