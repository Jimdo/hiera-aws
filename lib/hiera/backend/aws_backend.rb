require "hiera/backend/aws/elasticache"
require "hiera/backend/aws/rds"

class Hiera
  module Backend
    # Hiera AWS backend
    class Aws_backend # rubocop:disable ClassAndModuleCamelCase
      def initialize
        begin
          require "aws-sdk"
        rescue LoadError
          require "rubygems"
          require "aws-sdk"
        end

        setup_aws_credentials

        Hiera.debug("AWS backend initialized")
      end

      def setup_aws_credentials
        if Config[:aws] && Config[:aws][:access_key_id] && Config[:aws][:secret_access_key]
          Hiera.debug("Using AWS credentials from backend configuration")

          AWS.config(
            :access_key_id     => Config[:aws][:access_key_id],
            :secret_access_key => Config[:aws][:secret_access_key]
          )
        else
          Hiera.debug("Using AWS credentials from environment or IAM role")
        end
      end

      def lookup(key, scope, order_override, resolution_type) # rubocop:disable CyclomaticComplexity
        Backend.datasources(scope, order_override) do |elem|
          elements = elem.split "/"
          next unless elements[0] == "aws"

          service = elements[1]

          service_class = case service
                          when "elasticache"
                            Hiera::Backend::Aws::ElastiCache.new
                          when "rds"
                            Hiera::Backend::Aws::RDS.new
                          end
          next if service_class.nil?

          value = service_class.lookup(key, scope)
          next if value.nil?

          # this only supports resolution_type => :priority at the moment.
          # TODO: implement :array and :hash merging
          value = Backend.parse_answer(value, scope)
          return value unless value.nil?
        end
        nil
      end
    end
  end
end
