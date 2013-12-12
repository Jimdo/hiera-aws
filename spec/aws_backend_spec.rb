require "hiera/backend/aws_backend"

class Hiera
  module Backend
    describe Aws_backend do
      let(:backend) { Aws_backend.new }

      before do
        Hiera.stub(:debug)
      end

      describe "#lookup" do
        let(:key) { "some_key" }
        let(:scope) { { "foo" => "bar" } }
        let(:params) { [key, scope, "", :priority] }

        it "returns nil if hierarchy is empty" do
          Backend.stub(:datasources)
          expect(backend.lookup(*params)).to be_nil
        end

        it "returns nil if service is unknown" do
          Backend.stub(:datasources).and_yield "aws/unknown_service"
          expect(backend.lookup(*params)).to be_nil
        end

        it "properly forwards lookup to ElastiCache service" do
          Backend.stub(:datasources).and_yield "aws/elasticache"
          expect_any_instance_of(Aws::ElastiCache).to receive(:lookup).with(key, scope)
          backend.lookup(*params)
        end
      end
    end
  end
end
