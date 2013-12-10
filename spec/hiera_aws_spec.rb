require "rspec"
require "hiera/backend/aws_backend"

module Hiera
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

      it "properly instantiates a service if it is known" do
        Backend.stub(:datasources).and_yield "aws/elasticache"
        Aws::ElastiCache.should_receive(:new)
        backend.lookup("some_key", {}, "", :priority)
      end

      it "properly extracts service parameters from hierarchy" do
        Backend.stub(:datasources).and_yield "aws/elasticache/wurstbrot"
        Aws::ElastiCache.any_instance.should_receive(:lookup).with("some_key", "wurstbrot")
        backend.lookup("some_key", {}, "", :priority)
      end
    end
  end
end
