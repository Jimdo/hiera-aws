require "hiera/backend/aws/base"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::Base do
      describe "#lookup" do
        let(:service) { Aws::Base.new  }

        it "returns nil if key is unknown since Hiera iterates over all configured backends" do
          value = service.lookup("key_with_no_matching_method", {})
          expect(value).to be_nil
        end

        it "properly maps key to method and calls it" do
          expect(service).to receive :some_key
          service.lookup("some_key", {})
        end

        it "properly stores the scope (Puppet facts)" do
          scope = { "foo" => "bar" }
          service.stub(:some_key)
          service.lookup("some_key", scope)
          expect(scope).to eq scope
        end
      end

      describe "#aws_region" do
        it "defaults to eu-west-1" do
          service = Aws::Base.new
          expect(service.aws_region).to eq "eu-west-1"
        end

        it "can be set via Puppet fact" do
          scope = { "location" => "some-aws-region" }
          service = Aws::Base.new scope
          expect(service.aws_region).to eq "some-aws-region"
        end
      end

      describe "#aws_account_number" do
        it "can be set via Puppet fact" do
          scope = { "aws_account_number" => "12345678" }
          service = Aws::Base.new scope
          expect(service.aws_account_number).to eq "12345678"
        end

        it "is retrieved from AWS when Puppet fact is not set" do
          AWS::IAM.any_instance.stub(
            :users => [double(:arn => "arn:aws:iam::12345678:user/some-user")]
          )
          service = Aws::Base.new
          expect(service.aws_account_number).to eq "12345678"
        end
      end

      describe "#puppet_fact" do
        it "returns value of Puppet fact if fact exists" do
          service = Aws::Base.new "some-fact" => "some-value"
          expect(service.puppet_fact "some-fact").to eq "some-value"
        end

        it "returns nil if Puppet fact is nil" do
          service = Aws::Base.new
          expect(service.puppet_fact "some-fact").to eq nil
        end

        it "returns nil if Puppet fact is undefined" do
          service = Aws::Base.new "some-fact" => :undefined
          expect(service.puppet_fact "some-fact").to eq nil
        end
      end
    end
  end
end
