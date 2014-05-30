require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/rds
      class EC2 < Base
        def initialize(scope = {})
          super(scope)
          @client = AWS::EC2::Client.new
        end

        # Override default key lookup to implement custom format. Examples:
        #  - hiera("ec2_instances")
        #  - hiera("ec2_instances environment=dev")
        #  - hiera("ec2_instances role=mgmt-db")
        #  - hiera("ec2_instances environment=production role=mgmt-db")
        def lookup(key, scope)
          r = super(key, scope)
          return r if r

          args = key.split
          if args.shift == "ec2_instances"
            if args.length > 0
              tags = Hash[args.map { |t| t.split("=") }]
              ec2_instances_with_tags(tags)
            else
              ec2_instances
            end.map do |i|
              i[:instances_set].map do |e|
                prepare_instance_data(e)
              end
            end
          end
        end

        private

        def ec2_instances
          @client.describe_instances[:reservation_set] #.
          # @client.describe_instances[:ec2_instances] #.
            # select { |i| i[:ec2_instance_status] == "available" }
        end

        def ec2_instances_with_tags(tags)
          filters = Array.new
          tags.each do |tag|
            filters << { name: 'tag-key', values: [tag[0]] }
            filters << { name: 'tag-value', values: [tag[1]] }
          end
          @client.describe_instances(:filters => filters)[:reservation_set]
        end

#        def db_resource_name(db_instance_id)
#          "arn:aws:rds:#{aws_region}:#{aws_account_number}:db:#{db_instance_id}"
#        end

        def ec2_instance_tags(ec2_instance_id)
          tags = @client.list_tags_for_resource(:resource_name => ec2_resource_name(ec2_instance_id))
          Hash[tags[:tag_list].map { |t| [t[:key], t[:value]] }]
        end

        # Prepare RDS instance data for consumption by Puppet. For Puppet to
        # work, all hash keys have to be converted from symbols to strings.
        def prepare_instance_data(hash)
          {
            "ec2_instance_identifier" => hash.fetch(:instance_id),
            "ec2_private_dns_name" => hash.fetch(:private_dns_name),
            "ec2_private_ip_address" => hash.fetch(:private_ip_address),
            "ec2_ip_address" => hash.fetch(:ip_address),
            "data" => hash
          }
        end
      end
    end
  end
end
