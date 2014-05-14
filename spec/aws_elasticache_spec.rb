require "spec_helper"
require "hiera/backend/aws/elasticache"
require "date"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::ElastiCache do

      let(:ec2_client) do
        double(
          :instances => {
            "some-ec2-instance-id" => double(
              :tags => { "aws:cloudformation:stack-name" => "some-stack-name" }
            )
          }
        )
      end

      let(:cfn_client) do
        double(
          :stacks => {
            "some-stack-name" => double(
              :resources => [
                double(
                  :resource_type => "AWS::ElastiCache::CacheCluster",
                  :physical_resource_id => "some-redis-cluster-id"
                ),
                double(
                  :resource_type => "AWS::ElastiCache::CacheCluster",
                  :physical_resource_id => "another-redis-cluster-id"
                ),
                double(
                  :resource_type => "AWS::ElastiCache::CacheCluster",
                  :physical_resource_id => "some-memcache-cluster-id"
                ),
                double(
                  :resource_type => "AWS::ElastiCache::CacheCluster",
                  :physical_resource_id => "another-memcache-cluster-id"
                ),
              ]
            )
          }
        )
      end

      let(:elasticache) do
        scope = { "ec2_instance_id" => "some-ec2-instance-id" }
        Aws::ElastiCache.new scope
      end

      let(:some_cache_node) { { :endpoint => { :address => "1.1.1.1", :port => 1111 } } }
      let(:another_cache_node) { { :endpoint => { :address => "2.2.2.2", :port => 2222 } } }
      let(:third_cache_node) { { :endpoint => { :address => "3.3.3.3", :port => 3333 } } }
      let(:fourth_cache_node) { { :endpoint => { :address => "4.4.4.4", :port => 4444 } } }

      let(:some_redis_cache_cluster) do
        {
          :cache_nodes          => [some_cache_node, another_cache_node],
          :engine               => "redis",
          :cache_cluster_status => "available",
        }
      end

      let(:another_redis_cache_cluster) do
        {
          :cache_nodes          => [third_cache_node, fourth_cache_node],
          :engine               => "redis",
          :cache_cluster_status => "available",
        }
      end

      let(:redis_cache_clusters) do
        {
          :cache_clusters => [some_redis_cache_cluster, another_redis_cache_cluster]
        }
      end

      let(:some_memcache_cache_cluster) do
        {
          :cache_nodes          => [some_cache_node, another_cache_node],
          :engine               => "memcached",
          :cache_cluster_status => "available",
        }
      end

      let(:another_memcache_cache_cluster) do
        {
          :cache_nodes          => [third_cache_node, fourth_cache_node],
          :engine               => "memcached",
          :cache_cluster_status => "available",
        }
      end

      let(:memcache_cache_clusters) do
        {
          :cache_clusters => [some_memcache_cache_cluster, another_memcache_cache_cluster]
        }
      end

      let(:all_cache_clusters) do
        {
          :cache_clusters => redis_cache_clusters[:cache_clusters] + memcache_cache_clusters[:cache_clusters],
        }
      end

      let(:replication_groups) do
        {
          :replication_groups => [{
            :replication_group_id => "some-replication-group-id",
            :node_groups => [{
              :primary_endpoint => { :address => "some.replication.group.primary.endpoint", :port => 1234 },
            }],
            :status => "available",
          }]
        }
      end

      before(:each) do
        AWS::EC2.stub(:new => ec2_client)
        AWS::CloudFormation.stub(:new => cfn_client)
        @client = double

        allow(@client).to receive(:describe_cache_clusters).and_return(all_cache_clusters)

        allow(@client).to receive(:describe_cache_clusters).with(
                                                                   :cache_cluster_id => "some-redis-cluster-id",
                                                                   :show_cache_node_info => true
        ).and_return(:cache_clusters => [some_redis_cache_cluster])
        allow(@client).to receive(:describe_cache_clusters).with(
                                                                   :cache_cluster_id => "another-redis-cluster-id",
                                                                   :show_cache_node_info => true
        ).and_return(:cache_clusters => [another_redis_cache_cluster])

        allow(@client).to receive(:describe_cache_clusters).with(
                                                                   :cache_cluster_id => "some-memcache-cluster-id",
                                                                   :show_cache_node_info => true
        ).and_return(:cache_clusters => [some_memcache_cache_cluster])
        allow(@client).to receive(:describe_cache_clusters).with(
                                                                   :cache_cluster_id => "another-memcache-cluster-id",
                                                                   :show_cache_node_info => true
        ).and_return(:cache_clusters => [another_memcache_cache_cluster])

        allow(@client).to receive(:describe_replication_groups).with(:replication_group_id => "some-replication-group-id").and_return(replication_groups)
      end

      describe "#redis_cluster_nodes_for_cfn_stack" do

        it "raises an exception when ec2_instance_id fact is missing" do
          elasticache = Aws::ElastiCache.new
          expect do
            elasticache.redis_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Redis cluster nodes for CloudFormation stack of EC2 instance" do
          AWS::ElastiCache::Client.stub(:new => @client)
          expect(elasticache.redis_cluster_nodes_for_cfn_stack).to eq [
            { "endpoint" => { "address" => "1.1.1.1", "port" => 1111 } },
            { "endpoint" => { "address" => "2.2.2.2", "port" => 2222 } },
            { "endpoint" => { "address" => "3.3.3.3", "port" => 3333 } },
            { "endpoint" => { "address" => "4.4.4.4", "port" => 4444 } },
          ]
        end
      end

      describe "#redis_cluster_replica_groups_for_cfn_stack" do

        context "multiple defined cache clusters are in the same replica group" do

          let(:some_redis_cache_cluster) do
            super().merge :replication_group_id => "some-replication-group-id"
          end

          let(:another_redis_cache_cluster) do
            super().merge :replication_group_id => "some-replication-group-id"
          end

          it "returns a deduplicated list of Redis replica groups" do
            AWS::ElastiCache::Client.stub(:new => @client)

            expect(elasticache.redis_cluster_replica_groups_for_cfn_stack).to eq [
              {
                "replication_group_id" => "some-replication-group-id",
                "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 }
              },
            ]
          end
        end

        context "two replica groups with one cache cluster each, one cache cluster being newer than the other" do
          now = Time.new()
          later = now + 1

          let(:cache_clusters) do
            {
              :cache_clusters => [
                {
                  :cache_nodes          => [some_cache_node],
                  :replication_group_id => "some-group-id",
                  :engine               => "redis",
                  :cache_cluster_status => "available",
                  :cache_cluster_create_time => now,
                },
                {
                  :cache_nodes          => [another_cache_node],
                  :replication_group_id => "another-group-id",
                  :engine               => "redis",
                  :cache_cluster_status => "available",
                  :cache_cluster_create_time => later,
                },
              ]
            }
          end

          let(:replication_groups_some_cluster) do
            {
              :replication_groups => [{
                :replication_group_id => "some-group-id",
                :node_groups => [{
                  :primary_endpoint => { :address => "some.replication.group.primary.endpoint", :port => 1234 },
                }],
                :status => "available" }]
            }
          end

          let(:replication_groups_another_cluster) do
            {
              :replication_groups => [{
                :replication_group_id => "another-group-id",
                :node_groups => [{
                  :primary_endpoint => { :address => "another.replication.group.primary.endpoint", :port => 1234 },
                }],
                :status => "available" }]
            }
          end

          it "returns the most current cache cluster creation time for each replication group" do
            client = double
            allow(client).to receive(:describe_cache_clusters).and_return(cache_clusters)
            allow(client).to receive(:describe_replication_groups).with(:replication_group_id => "some-group-id").and_return(replication_groups_some_cluster)
            allow(client).to receive(:describe_replication_groups).with(:replication_group_id => "another-group-id").and_return(replication_groups_another_cluster)
            AWS::ElastiCache::Client.stub(:new => client)

            expect(elasticache.redis_cluster_replica_groups_for_cfn_stack).to eq [
              {
                "replication_group_id" => "some-group-id",
                "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 },
                "latest_cache_cluster_create_time" => now,
              },
              {
                "replication_group_id" => "another-group-id",
                "primary_endpoint"     => { "address" => "another.replication.group.primary.endpoint", "port" => 1234 },
                "latest_cache_cluster_create_time" => later,
              },
            ]
          end
        end
      end

      describe "#memcached_cluster_nodes_for_cfn_stack" do
        it "raises an exception when ec2_instance_id fact is missing" do
          elasticache = Aws::ElastiCache.new
          expect do
            elasticache.memcached_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Memcached cluster nodes for CloudFormation stack of EC2 instance" do
          AWS::ElastiCache::Client.stub(:new => @client)
          expect(elasticache.memcached_cluster_nodes_for_cfn_stack).to eq ["1.1.1.1", "2.2.2.2", "3.3.3.3", "4.4.4.4"]
        end
      end
    end
  end
end
