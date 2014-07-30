require "spec_helper"
require "hiera/backend/aws/cloudformation"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::Cloudformation do
      let(:cfn) { Aws::Cloudformation.new }
      let(:some_cfn_output_key) { "some_output_key" }
      let(:some_cfn_output_value) { "some_value" }
      let(:some_cfn_stack_name) { "some_stack_name" }

      before do
        AWS.stub(:config).and_return(double(:region => "some-region"))
        cfn_client = double
        allow(cfn_client).to receive(:describe_stacks).with(:stack_name => some_cfn_stack_name).and_return(
          :stacks => [
            {
              :outputs => [
                {
                  :output_key   => some_cfn_output_key,
                  :output_value => some_cfn_output_value,
                  :description  => "foobar",
                }
              ]
            }
          ]
        )
        AWS::CloudFormation::Client.stub(:new).and_return(cfn_client)
      end

      describe "#lookup" do
        let(:scope) { {} }

        it "returns nil if Hiera key is unknown" do
          expect(cfn.lookup("some_unknown_key", scope)).to be_nil
        end

        it "returns the value of the given cfn stack output" do
          expect(cfn.lookup("cloudformation stack=#{some_cfn_stack_name} output=#{some_cfn_output_key}", scope)).to eq some_cfn_output_value
        end

        it "returns the value of the given cfn stack output regardless of parameter order" do
          expect(cfn.lookup("cloudformation output=#{some_cfn_output_key} stack=#{some_cfn_stack_name}", scope)).to eq some_cfn_output_value
        end

        it "fails if stack is not given" do
          expect { cfn.lookup("cloudformation output=#{some_cfn_output_key}", scope) }.to raise_exception
        end

        it "fails if output key is not given" do
          expect { cfn.lookup("cloudformation stack=#{some_cfn_stack_name}", scope) }.to raise_exception
        end

        it "fails if queried stack does not exist" do
          expect { cfn.lookup("cloudformation stack=some_non_existing_stack output=#{some_cfn_output_key}", scope) }.to raise_exception
        end

        it "fails if queried outputkey does not exist" do
          expect { cfn.lookup("cloudformation stack=#{some_cfn_stack_name} output=non_existing_output_key", scope) }.to raise_exception
        end

      end
    end
  end
end
