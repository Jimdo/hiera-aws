require "hiera/backend/aws_backend"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws_backend do
      before do
        Hiera.stub(:debug)
      end

      describe "#initialize" do
        it "does not change AWS configuration by default" do
          Config.stub(:[]).with(:aws)
          expect(AWS).to_not receive(:config)
          Aws_backend.new
        end

        it "uses AWS credentials from backend configuration if provided" do
          credentials = {
            :access_key_id     => "some_access_key_id",
            :secret_access_key => "some_secret_access_key"
          }

          Config.stub(:[]).with(:aws).and_return(credentials)
          expect(AWS).to receive(:config).with(credentials)
          Aws_backend.new
        end

        it "uses particular AWS region if provided" do
          aws_config = {
            :region => "some_aws_region"
          }

          Config.stub(:[]).with(:aws).and_return(aws_config)
          expect(AWS).to receive(:config).with(aws_config)
          Aws_backend.new
        end
      end

      describe "#lookup" do
        let(:backend) { Aws_backend.new }
        let(:key) { "some_key" }
        let(:scope) { { "foo" => "bar" } }
        let(:params) { [key, scope, "", :priority] }

        before do
          Config.stub(:[]).with(:aws)
        end

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

        it "properly forwards lookup to RDS service" do
          Backend.stub(:datasources).and_yield "aws/rds"
          expect_any_instance_of(Aws::RDS).to receive(:lookup).with(key, scope)
          backend.lookup(*params)
        end

        it "returns nil if service returns empty result" do
          empty_result = []
          Backend.stub(:datasources).and_yield "aws/rds"
          Backend.stub(:parse_answer).and_return(empty_result)
          Aws::RDS.stub(:new).and_return(double(:lookup => empty_result))
          expect(backend.lookup(*params)).to be_nil
        end
      end
    end
  end
end
