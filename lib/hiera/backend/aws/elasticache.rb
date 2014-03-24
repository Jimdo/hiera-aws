require "hiera/backend/aws/base"

class Hiera
  module Backend
    module Aws
      # Implementation of Hiera keys for aws/elasticache
      class ElastiCache < Base
          #
        # XXX: Lots of spiked code ahead that MUST be refactored.
        #
        def cfn_stack_name(instance_id)
          client = AWS::EC2.new
          instances = client.instances[instance_id]
          instances.tags["aws:cloudformation:stack-name"]
        end

        def cache_cluster_info(cluster_id)
          client = AWS::ElastiCache::Client.new
          options = { :cache_cluster_id => cluster_id, :show_cache_node_info => true }
          info = client.describe_cache_clusters(options)
          info.fetch(:cache_clusters).first
        end

        # rubocop:disable MultilineBlockChain
        def cache_clusters_in_cfn_stack(stack_name, cluster_engine = nil)
          client = AWS::CloudFormation.new

          stack = client.stacks[stack_name]
          stack.resources.select do |r|
            r.resource_type == "AWS::ElastiCache::CacheCluster"
          end.map do |r|
            cluster_id = r.physical_resource_id
            cache_cluster_info(cluster_id)
          end.select do |cluster|
            # Filter by engine type if provided
            if cluster_engine
              cluster.fetch(:engine) == cluster_engine.to_s
            else
              true
            end
          end
        end
        # rubocop:enable MultilineBlockChain

        def cluster_nodes_for_cfn_stack(cluster_engine = nil)
          ec2_instance_id = scope["ec2_instance_id"]
          raise MissingFactError, "ec2_instance_id not found" unless ec2_instance_id

          stack_name = cfn_stack_name(ec2_instance_id)
          endpoints = []
          clusters = cache_clusters_in_cfn_stack(stack_name, cluster_engine)
          clusters.each do |cluster|
            nodes = cluster.fetch(:cache_nodes)
            endpoints += nodes.map { |node| { "endpoint" => stringify_keys(node.fetch(:endpoint)) } }
          end
          endpoints
        end

        def cluster_replica_groups_for_cfn_stack(cluster_engine = nil)
          ec2_instance_id = scope["ec2_instance_id"]
          raise MissingFactError, "ec2_instance_id not found" unless ec2_instance_id

          replica_groups = {}
          stack_name = cfn_stack_name(ec2_instance_id)

          clusters = cache_clusters_in_cfn_stack(stack_name, cluster_engine)
          clusters.each do |cluster|
            replication_group_id = cluster[:replication_group_id]
            next unless replication_group_id

            client = AWS::ElastiCache::Client.new
            replication_group = client.describe_replication_groups(:replication_group_id => replication_group_id).fetch(:replication_groups).first

            primary_endpoint = replication_group.fetch(:node_groups).first.fetch(:primary_endpoint)

            replica_groups[replication_group_id] = {
              :primary_endpoint => primary_endpoint
            }
          end

          replica_groups.map do |k, v|
            {
              "replication_group_id" => k,
              "primary_endpoint"     => stringify_keys(v[:primary_endpoint])
            }
          end
        end

        def redis_cluster_replica_groups_for_cfn_stack
          cluster_replica_groups_for_cfn_stack(:redis)
        end

        def redis_cluster_nodes_for_cfn_stack
          cluster_nodes_for_cfn_stack(:redis)
        end

        def memcached_cluster_nodes_for_cfn_stack
          cluster_nodes_for_cfn_stack(:memcached)
        end
      end
    end
  end
end
