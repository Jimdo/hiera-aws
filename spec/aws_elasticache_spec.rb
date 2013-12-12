require "hiera/backend/aws/elasticache"

class Hiera
  module Backend
    describe Aws::ElastiCache do
      describe "#client" do
        it "returns an instance of AWS::ElastiCache::Client" do
          elasticache = Aws::ElastiCache.new
          client = double
          AWS::ElastiCache::Client.stub(:new => client)
          elasticache.client.should == client
        end

        it "configures the default AWS region eu-west-1" do
          elasticache = Aws::ElastiCache.new
          AWS::ElastiCache::Client.should_receive(:new).with(:region => "eu-west-1")
          elasticache.client
        end

        it "configures a custom AWS region passed via 'location' fact" do
          scope = { "location" => "some-aws-region" }
          elasticache = Aws::ElastiCache.new scope
          AWS::ElastiCache::Client.should_receive(:new).with(:region => "some-aws-region")
          elasticache.client
        end
      end

      describe "#cache_nodes_by_cache_cluster_id" do
        it "raises an exception when called without cache_cluster_id set" do
          scope = {}
          elasticache = Aws::ElastiCache.new scope
          expect do
            elasticache.cache_nodes_by_cache_cluster_id
          end.to raise_error Aws::MissingFactError
        end

        it "returns all nodes in cache cluster" do
          cluster_id = "some_cluster_id"
          scope = { "cache_cluster_id" => cluster_id }
          elasticache = Aws::ElastiCache.new scope

          cluster_info = {
            :cache_clusters => [{
              :cache_nodes => [
                { :endpoint => { :address => "1.2.3.4", :port => 1234 } },
                { :endpoint => { :address => "5.6.7.8", :port => 5678 } },
              ]
            }]
          }
          options = { :cache_cluster_id => cluster_id, :show_cache_node_info => true }
          client = Object.new
          client.stub(:describe_cache_clusters).with(options).and_return(cluster_info)
          AWS::ElastiCache::Client.stub(:new => client)

          elasticache.cache_nodes_by_cache_cluster_id.should == ["1.2.3.4:1234", "5.6.7.8:5678"]
        end
      end
    end
  end
end
