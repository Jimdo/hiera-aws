require "spec_helper"
require "hiera/backend/aws/cloudformation"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::CloudFormation do
      let(:cloudformation) { Aws::CloudFormation.new }

      before do
        output = double
        allow(output).to receive(:key) { 'the-key' }
        allow(output).to receive(:value) { 'the-value' }

        stack = double
        allow(stack).to receive(:outputs) { [output] }

        allow(AWS).to receive(:config) { double(:region => "some-region") }

        cloudformation_client = double
        allow(AWS::CloudFormation).to receive(:new) { cloudformation_client }
        allow(cloudformation_client).to receive(:stacks) { { 'the-stack' => stack } }
      end

      describe "#lookup" do
        let(:scope) {}

        it "returns nil if Hiera key is unknown" do
          expect(cloudformation.lookup("doge", scope)).to be_nil
        end

        it "returns nil if no stack is specified" do
          expect(cloudformation.lookup("cloudformation", scope)).to be_nil
        end

        it "returns nil if no stack property is specified" do
          expect(cloudformation.lookup("cloudformation/the-stack", scope)).to be_nil
        end

        it "returns nil if no stack property is specified" do
          expect(cloudformation.lookup("cloudformation/the-stack", scope)).to be_nil
        end

        it "returns nil if no output key is specified" do
          expect(cloudformation.lookup("cloudformation/the-stack/output", scope)).to be_nil
        end

        it "returns nil if the output key does not exist for the stack" do
          expect(cloudformation.lookup("cloudformation/the-stack/output/non-existing-key", scope)).to be_nil
        end

        it "returns the keys value for an existing key" do
          expect(cloudformation.lookup("cloudformation/the-stack/output/the-key", scope)).to eq("the-value")
        end
      end
    end
  end
end
