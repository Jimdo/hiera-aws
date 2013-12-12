require "hiera/backend/aws_backend"

class Hiera
  module Backend
    describe Aws_backend do
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
    end
  end
end
