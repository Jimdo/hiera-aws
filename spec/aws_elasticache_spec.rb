require "hiera/backend/aws/elasticache"

class Hiera
  module Backend
    describe Aws::ElastiCache do
      describe "#cache_nodes_by_cache_cluster_id" do
        it "raises an exception when called without cache_cluster_id set" do
          scope = {}
          elasticache = Aws::ElastiCache.new scope
          expect do
            elasticache.cache_nodes_by_cache_cluster_id
          end.to raise_error Aws::MissingFactError
        end

        it "returns all nodes in cache cluster" do
          scope = { "cache_cluster_id" => "some-cluster-id" }
          elasticache = Aws::ElastiCache.new scope

          ec_client = double(
            :describe_cache_clusters => {
              :cache_clusters => [{
                :cache_nodes => [
                  { :endpoint => { :address => "1.2.3.4", :port => 1234 } },
                  { :endpoint => { :address => "5.6.7.8", :port => 5678 } },

                ],
                :engine => "redis"
              }]
            }
          )
          AWS::ElastiCache::Client.stub(:new => ec_client)

          expect(elasticache.cache_nodes_by_cache_cluster_id).to eq ["1.2.3.4:1234", "5.6.7.8:5678"]
        end
      end

      describe "#redis_cluster_nodes_for_cfn_stack" do
        it "raises an exception when ec2_instance_id fact is missing" do
          scope = {}
          elasticache = Aws::ElastiCache.new scope
          expect do
            elasticache.redis_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Redis cluster nodes for CloudFormation stack of EC2 instance" do
          ec2_client = double(
            :instances => {
              "some-ec2-instance-id" => double(
                :tags => { "aws:cloudformation:stack-name" => "some-stack-name" }
              )
          })
          AWS::EC2.stub(:new => ec2_client)

          cfn_client = double(
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
          AWS::CloudFormation.stub(:new => cfn_client)

          ec_client = double(
            :describe_cache_clusters => {
              :cache_clusters => [{
                :cache_nodes => [
                  { :endpoint => { :address => "1.2.3.4" } },
                  { :endpoint => { :address => "5.6.7.8" } },
                ],
                :engine => "redis"
              }]
            }
          )
          AWS::ElastiCache::Client.stub(:new => ec_client)

          scope = { "ec2_instance_id" => "some-ec2-instance-id" }
          elasticache = Aws::ElastiCache.new scope
          expect(elasticache.redis_cluster_nodes_for_cfn_stack).to eq ["1.2.3.4", "5.6.7.8"]
        end
      end

      describe "#memcached_cluster_nodes_for_cfn_stack" do
        it "raises an exception when ec2_instance_id fact is missing" do
          scope = {}
          elasticache = Aws::ElastiCache.new scope
          expect do
            elasticache.memcached_cluster_nodes_for_cfn_stack
          end.to raise_error Aws::MissingFactError
        end

        it "returns all Memcached cluster nodes for CloudFormation stack of EC2 instance" do
          ec2_client = double(
            :instances => {
              "some-ec2-instance-id" => double(
                :tags => { "aws:cloudformation:stack-name" => "some-stack-name" }
              )
          })
          AWS::EC2.stub(:new => ec2_client)

          cfn_client = double(
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
          AWS::CloudFormation.stub(:new => cfn_client)

          ec_client = double(
            :describe_cache_clusters => {
              :cache_clusters => [{
                :cache_nodes => [
                  { :endpoint => { :address => "1.2.3.4" } },
                  { :endpoint => { :address => "5.6.7.8" } },
                ],
                :engine => "memcached"
              }]
            }
          )
          AWS::ElastiCache::Client.stub(:new => ec_client)

          scope = { "ec2_instance_id" => "some-ec2-instance-id" }
          elasticache = Aws::ElastiCache.new scope
          expect(elasticache.memcached_cluster_nodes_for_cfn_stack).to eq ["1.2.3.4", "5.6.7.8"]
        end
      end
    end
  end
end
