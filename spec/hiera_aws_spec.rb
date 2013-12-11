require "rspec"
require "hiera/backend/aws_backend"

class Hiera
  module Backend
    describe "Aws_Backend" do
      let(:backend) { Aws_backend.new }

      before do
        Hiera.stub(:debug)
      end

      it "returns nil on empty hierarchy" do
        Backend.stub(:datasources)
        expect(backend.lookup("some_key", {}, "", :priority)).to be_nil
      end

      it "returns nil if unknown service is given" do
        Backend.stub(:datasources).and_yield "aws/unknown_service"
        expect(backend.lookup("some_key", {}, "", :priority)).to be_nil
      end

      it "properly instantiates ElastiCache" do
        Backend.stub(:datasources).and_yield "aws/elasticache"
        Aws::ElastiCache.should_receive(:new)
        backend.lookup("some_key", {}, "", :priority)
      end

      context "ElastiCache" do
        let(:elasticache) { Aws::ElastiCache.new  }

        it "raises an exception when called with unhandled key" do
          expect do
            elasticache.lookup("key_with_no_matching_method", {})
          end.to raise_error Aws::NoHandlerError
        end

        it "properly maps keys to methods and calls those" do
          scope = {"foo" => "bar"}
          elasticache.should_receive(:cache_nodes_by_cache_cluster_id)
          elasticache.lookup("cache_nodes_by_cache_cluster_id", scope)
        end

        context "#cache_nodes_by_cache_cluster_id" do
          it "raises an exception when called without cache_cluster_id set" do
            expect do
              elasticache.cache_nodes_by_cache_cluster_id
            end.to raise_error Aws::MissingFactError
          end

          it "returns all nodes in cache cluster" do
            cluster_id = "some_cluster_id"
            cluster_info = {
              :cache_clusters => [{
                :cache_nodes => [
                  { :endpoint => { :address => "1.2.3.4", :port => 1234 } },
                  { :endpoint => { :address => "5.6.7.8", :port => 5678 } },
                ]
              }]
            }
            options = { :cache_cluster_id => cluster_id, :show_cache_node_info => true }

            client = double
            client.stub(:describe_cache_clusters).with(options).and_return(cluster_info)
            elasticache.stub(:client).and_return(client)

            elasticache.instance_variable_set("@scope", { "cache_cluster_id" => cluster_id })
            elasticache.cache_nodes_by_cache_cluster_id.
              should eq ["1.2.3.4:1234", "5.6.7.8:5678"]
          end
        end
      end
    end
  end
end
