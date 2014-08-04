require "hiera/backend/aws/elasticache"
require "hiera/backend/aws/rds"
require "hiera/backend/aws/cloudformation"

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

        setup_aws_config

        Hiera.debug("AWS backend initialized")
      end

      def lookup(key, scope, order_override, resolution_type) # rubocop:disable UnusedMethodArgument
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

      def setup_aws_config
        return unless Config[:aws]

        aws_config = {}

        if Config[:aws][:access_key_id] && Config[:aws][:secret_access_key]
          Hiera.debug("Using AWS credentials from backend configuration")
          aws_config[:access_key_id] = Config[:aws][:access_key_id]
          aws_config[:secret_access_key] = Config[:aws][:secret_access_key]
        else
          Hiera.debug("Using AWS credentials from environment or IAM role")
        end

        region = Config[:aws][:region]
        if region
          Hiera.debug("Using AWS region '#{region}' from backend configuration")
          aws_config[:region] = region
        else
          Hiera.debug("Using default AWS region")
        end

        AWS.config(aws_config)
      end

      def find_service_class(source)
        elements = source.split "/"
        return nil unless elements[0] == "aws"

        case elements[1]
        when "elasticache"
          Hiera::Backend::Aws::ElastiCache.new
        when "rds"
          Hiera::Backend::Aws::RDS.new
        when "cloudformation"
          Hiera::Backend::Aws::Cloudformation.new
        else
          nil
        end
      end
    end
  end
end
