require "hiera/backend/aws/elasticache"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::ElastiCache do
      let(:redis_cache_clusters) do
        {
          :cache_clusters => [{
            :cache_nodes => [
              { :endpoint => { :address => "1.1.1.1", :port => 1234 } },
              { :endpoint => { :address => "2.2.2.2", :port => 1234 } }

            ],
            :engine => "redis"
          }]
        }
      end
      let(:memcached_cache_clusters) do
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

      before do
        AWS::EC2.stub(:new => ec2_client)
        AWS::CloudFormation.stub(:new => cfn_client)
      end

      describe "#redis_cluster_nodes_for_cfn_stack" do
        it "raises an exception when ec2_instance_id fact is missing" do
          elasticache = Aws::ElastiCache.new
          expect do
            elasticache.redis_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Redis cluster nodes for CloudFormation stack of EC2 instance" do
          scope = { "ec2_instance_id" => "some-ec2-instance-id" }
          elasticache = Aws::ElastiCache.new scope

          ec_redis_client = double
          allow(ec_redis_client).to receive(:describe_cache_clusters).and_return(redis_cache_clusters)
          AWS::ElastiCache::Client.stub(:new => ec_redis_client)

          expect(elasticache.redis_cluster_nodes_for_cfn_stack).to eq [
            {
              "endpoint" => { "address" => "1.1.1.1", "port" => 1234 }
            },
            {
              "endpoint" => { "address" => "2.2.2.2", "port" => 1234 }
            }
          ]
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
          scope = { "ec2_instance_id" => "some-ec2-instance-id" }
          elasticache = Aws::ElastiCache.new scope

          ec_memcached_client = double
          allow(ec_memcached_client).to receive(:describe_cache_clusters).and_return(memcached_cache_clusters)
          AWS::ElastiCache::Client.stub(:new => ec_memcached_client)

          expect(elasticache.memcached_cluster_nodes_for_cfn_stack).to eq [
            {
              "endpoint" => { "address" => "3.3.3.3", "port" => 5678 }
            },
            {
              "endpoint" => { "address" => "4.4.4.4", "port" => 5678 }
            }
          ]
        end
      end
    end
  end
end
