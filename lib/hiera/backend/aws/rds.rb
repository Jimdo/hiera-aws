require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/rds
      class RDS < Base
        def initialize(scope = {})
          super(scope)
          @client = AWS::RDS::Client.new :region => aws_region
        end

        # Override default key lookup to implement custom format. Examples:
        #  - hiera("rds")
        #  - hiera("rds environment=dev")
        #  - hiera("rds role=mgmt-db")
        #  - hiera("rds environment=production role=mgmt-db")
        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split
          if args.shift == "rds"
            if args.length > 0
              tags = Hash[args.map { |t| t.split("=") }]
              db_instances_with_tags(tags)
            else
              db_instances
            end
          end
        end

        private

        def db_instances
          @db_instances ||= @client.describe_db_instances[:db_instances].map do |i|
            {
              "db_instance_identifier" => i.fetch(:db_instance_identifier),
              "endpoint"               => stringify_keys(i.fetch(:endpoint))
            }
          end
        end

        def db_instances_with_tags(tags)
          db_instances.select do |i|
            all_tags = db_instance_tags(i["db_instance_identifier"])
            tags.all? { |k, v| tags[k] == all_tags[k] }
          end
        end

        def db_resource_name(db_instance_id)
          "arn:aws:rds:#{aws_region}:#{aws_account_number}:db:#{db_instance_id}"
        end

        def db_instance_tags(db_instance_id)
          tags = @client.list_tags_for_resource(:resource_name => db_resource_name(db_instance_id))
          Hash[tags[:tag_list].map { |t| [t[:key], t[:value]] }]
        end
      end
    end
  end
end
