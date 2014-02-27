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

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up '#{key}' in AWS backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")

          service_class = find_service_class(source)
          next unless service_class

          value = service_class.lookup(key, scope)
          next if value.nil? || value.empty?

          answer = Backend.parse_answer(value, scope)
          break if answer
        end
        answer
      end

      private

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

      def find_service_class(source)
        elements = source.split "/"
        return nil unless elements[0] == "aws"

        case elements[1]
        when "elasticache"
          Hiera::Backend::Aws::ElastiCache.new
        when "rds"
          Hiera::Backend::Aws::RDS.new
        else
          nil
        end
      end
    end
  end
end
