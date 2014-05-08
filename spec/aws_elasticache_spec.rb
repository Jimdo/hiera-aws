require "hiera/backend/aws/elasticache"

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
                  :physical_resource_id => "some-cluster-id"
                )
              ]
            )
          }
        )
      end
      let(:elasticache) do
        scope = { "ec2_instance_id" => "some-ec2-instance-id" }
        Aws::ElastiCache.new scope
      end

      let(:some_cache_node) { { :endpoint => { :address => "1.1.1.1", :port => 1234 } } }
      let(:another_cache_node) { { :endpoint => { :address => "2.2.2.2", :port => 1234 } } }

      before do
        AWS::EC2.stub(:new => ec2_client)
        AWS::CloudFormation.stub(:new => cfn_client)
      end

      describe "#redis_cluster_nodes_for_cfn_stack" do
        let(:cache_clusters) do
          {
            :cache_clusters => [{
              :cache_nodes => [
                some_cache_node,
                another_cache_node

              ],
              :engine => "redis"
            }]
          }
        end

        it "raises an exception when ec2_instance_id fact is missing" do
          elasticache = Aws::ElastiCache.new
          expect do
            elasticache.redis_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Redis cluster nodes for CloudFormation stack of EC2 instance" do
          client = double
          allow(client).to receive(:describe_cache_clusters).and_return(cache_clusters)
          AWS::ElastiCache::Client.stub(:new => client)

          expect(elasticache.redis_cluster_nodes_for_cfn_stack).to eq [
            { "endpoint" => { "address" => "1.1.1.1", "port" => 1234 } },
            { "endpoint" => { "address" => "2.2.2.2", "port" => 1234 } },
          ]
        end
      end

      describe "#redis_cluster_replica_groups_for_cfn_stack" do
        let(:cache_clusters) do
          {
            :cache_clusters => [{
              :cache_nodes => [
                some_cache_node,

              ],
              :replication_group_id => "some-group-id",
              :engine => "redis",
            }]
          }
        end
        let(:replication_groups) do
          {
            :replication_groups => [{
              :node_groups => [{
                :primary_endpoint => { :address => "some.replication.group.primary.endpoint", :port => 1234 }
              }]
            }]
          }
        end

        it "returns all Redis replica groups for CloudFormation stack of EC2 instance" do
          client = double
          allow(client).to receive(:describe_cache_clusters).and_return(cache_clusters)
          allow(client).to receive(:describe_replication_groups).with(:replication_group_id => "some-group-id").and_return(replication_groups)
          AWS::ElastiCache::Client.stub(:new => client)

          expect(elasticache.redis_cluster_replica_groups_for_cfn_stack).to eq [
            {
              "replication_group_id" => "some-group-id",
              "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 }
            },
          ]
        end

        context "multiple defined cache clusters are in the same replica group" do
          let(:cache_clusters) do
            {
              :cache_clusters => [
                {
                  :cache_nodes => [
                    some_cache_node,
                  ],
                  :replication_group_id => "some-group-id",
                  :engine => "redis",
                },
                {
                  :cache_nodes => [
                    another_cache_node,
                  ],
                  :replication_group_id => "some-group-id",
                  :engine => "redis",
                },
              ]
            }
          end
          let(:replication_groups) do
            {
              :replication_groups => [{
                :node_groups => [{
                  :primary_endpoint => { :address => "some.replication.group.primary.endpoint", :port => 1234 }
                }]
              }]
            }
          end

          it "returns a deduplicated list of Redis replica groups" do
            client = double
            allow(client).to receive(:describe_cache_clusters).and_return(cache_clusters)
            allow(client).to receive(:describe_replication_groups).with(:replication_group_id => "some-group-id").and_return(replication_groups)
            AWS::ElastiCache::Client.stub(:new => client)

            expect(elasticache.redis_cluster_replica_groups_for_cfn_stack).to eq [
              {
                "replication_group_id" => "some-group-id",
                "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 }
              },
            ]
          end
        end

        context "one defined cluster is found without replica group" do
          let(:cfn_client) do
            double(
              :stacks => {
                "some-stack-name" => double(
                  :resources => [
                    double(
                      :resource_type => "AWS::ElastiCache::CacheCluster",
                      :physical_resource_id => "some-cluster-id"
                    ),
                    double(
                      :resource_type => "AWS::ElastiCache::CacheCluster",
                      :physical_resource_id => "another-cluster-id"
                    ),
                  ]
                )
              }
            )
          end
          let(:cache_clusters) do
            {
              "some-cluster-id" => {
                :cache_clusters => [
                  {
                    :cache_nodes => [
                      some_cache_node,
                    ],
                    :replication_group_id => "some-group-id",
                    :engine => "redis",
                  },
                ]
              },
              "another-cluster-id" => {
                :cache_clusters => [
                  {
                    :cache_nodes => [
                      another_cache_node,
                    ],
                    :engine => "redis",
                  },
                ]
              }
            }
          end
          let(:replication_groups) do
            {
              :replication_groups => [{
                :node_groups => [{
                  :primary_endpoint => { :address => "some.replication.group.primary.endpoint", :port => 1234 }
                }]
              }]
            }
          end

          it "returns all Redis replica groups and does not fail" do

            client = double
            allow(client).to receive(:describe_cache_clusters) do |options|
              cache_clusters.fetch(options.fetch(:cache_cluster_id))
            end

            allow(client).to receive(:describe_replication_groups).with(:replication_group_id => "some-group-id").and_return(replication_groups)
            AWS::ElastiCache::Client.stub(:new => client)

            expect(elasticache.redis_cluster_replica_groups_for_cfn_stack).to eq [
              {
                "replication_group_id" => "some-group-id",
                "primary_endpoint"     => { "address" => "some.replication.group.primary.endpoint", "port" => 1234 }
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

        context "single cache cluster" do
          let(:cache_clusters) do
            {
              :cache_clusters => [{
                :cache_nodes => [
                  { :endpoint => { :address => "3.3.3.3", :port => 5678 } },
                  { :endpoint => { :address => "4.4.4.4", :port => 5678 } }

                ],
                :engine => "memcached"
              }]
            }
          end

          it "returns all Memcached cluster nodes for CloudFormation stack of EC2 instance" do
            client = double
            allow(client).to receive(:describe_cache_clusters).and_return(cache_clusters)
            AWS::ElastiCache::Client.stub(:new => client)

            expect(elasticache.memcached_cluster_nodes_for_cfn_stack).to eq ["3.3.3.3", "4.4.4.4"]
          end
        end
      end
    end
  end
end
