require "hiera/backend/aws/elasticache"

class Hiera
  module Backend
    describe Aws::ElastiCache do
      let(:ec_redis_client) { double(
        :describe_cache_clusters => {
          :cache_clusters => [{
            :cache_nodes => [
              { :endpoint => { :address => "1.1.1.1", :port => 1234 } },
              { :endpoint => { :address => "2.2.2.2", :port => 1234 } },

            ],
            :engine => "redis"
          }]
        }
      )}
      let(:ec_memcached_client) { double(
        :describe_cache_clusters => {
          :cache_clusters => [{
            :cache_nodes => [
              { :endpoint => { :address => "3.3.3.3", :port => 5678 } },
              { :endpoint => { :address => "4.4.4.4", :port => 5678 } },

            ],
            :engine => "memcached"
          }]
        }
      )}
      let(:ec2_client) { double(
        :instances => {
          "some-ec2-instance-id" => double(
            :tags => { "aws:cloudformation:stack-name" => "some-stack-name" }
          )
        }
      )}
      let(:cfn_client) { double(
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
      )}

      before do
        AWS::EC2.stub(:new => ec2_client)
        AWS::CloudFormation.stub(:new => cfn_client)
      end

      describe "#cache_nodes_by_cache_cluster_id" do
        it "raises an exception when called without cache_cluster_id set" do
          elasticache = Aws::ElastiCache.new
          expect do
            elasticache.cache_nodes_by_cache_cluster_id
          end.to raise_error Aws::MissingFactError
        end

        it "returns all nodes in cache cluster" do
          scope = { "cache_cluster_id" => "some-cluster-id" }
          elasticache = Aws::ElastiCache.new scope
          AWS::ElastiCache::Client.stub(:new => ec_redis_client)
          expect(elasticache.cache_nodes_by_cache_cluster_id).to eq ["1.1.1.1:1234", "2.2.2.2:1234"]
        end
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
          AWS::ElastiCache::Client.stub(:new => ec_redis_client)
          expect(elasticache.redis_cluster_nodes_for_cfn_stack).to eq ["1.1.1.1", "2.2.2.2"]
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
          AWS::ElastiCache::Client.stub(:new => ec_memcached_client)
          expect(elasticache.memcached_cluster_nodes_for_cfn_stack).to eq ["3.3.3.3", "4.4.4.4"]
        end
      end
    end
  end
end
