require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/rds
      class RDS < Base
        def initialize(scope = {})
          super(scope)
          @client = AWS::RDS::Client.new
        end

        # Override default key lookup to implement custom format. Examples:
        #  - hiera("rds_instances")
        #  - hiera("rds_instances environment=dev")
        #  - hiera("rds_instances role=mgmt-db")
        #  - hiera("rds_instances environment=production role=mgmt-db")
        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split
          return if args.shift != "rds_instances"
          if args.length > 0
            tags = Hash[args.map { |t| t.split("=") }]
            db_instances_with_tags(tags)
          else
            db_instances
          end.map { |i| prepare_instance_data(i) }
        end

        private

        def db_instances
          @client.describe_db_instances[:db_instances].
            select { |i| i[:db_instance_status] == "available" }
        end

        def db_instances_with_tags(tags)
          db_instances.select do |i|
            all_tags = db_instance_tags(i.fetch(:db_instance_identifier))
            tags.all? { |k, _| tags[k] == all_tags[k] }
          end
        end

        def db_resource_name(db_instance_id)
          "arn:aws:rds:#{aws_region}:#{aws_account_number}:db:#{db_instance_id}"
        end

        def db_instance_tags(db_instance_id)
          tags = @client.list_tags_for_resource(:resource_name => db_resource_name(db_instance_id))
          Hash[tags[:tag_list].map { |t| [t[:key], t[:value]] }]
        end

        # Prepare RDS instance data for consumption by Puppet. For Puppet to
        # work, all hash keys have to be converted from symbols to strings.
        def prepare_instance_data(hash)
          {
            "db_instance_identifier" => hash.fetch(:db_instance_identifier),
            "endpoint"               => stringify_keys(hash.fetch(:endpoint)),
            "engine"                 => hash.fetch(:engine)
          }
        end
      end
    end
  end
end
