require "hiera/backend/aws/elasticache"

class Hiera
  module Backend
    class Aws_backend
      def initialize
        begin
          require "aws-sdk"
        rescue LoadError
          require "rubygems"
          require "aws-sdk"
        end

        Hiera.debug("AWS backend initialized")
      end

      def lookup(key, scope, order_override, resolution_type)
        Backend.datasources(scope, order_override) do |elem|
          elements = elem.split "/"
          next unless elements[0] == "aws"

          service = elements[1]

          service_class = case service
                          when "elasticache"
                            Hiera::Backend::Aws::ElastiCache.new
                          end
          next if service_class.nil?

          value = service_class.lookup(key, scope)
          next if value.nil?

          # this only supports resolution_type => :priority at the moment.
          # TODO implement :array and :hash merging
          value = Backend.parse_answer(value, scope)
          return value unless value.nil?
        end
        nil
      end
    end
  end
end
