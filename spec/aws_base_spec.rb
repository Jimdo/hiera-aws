require "hiera/backend/aws/base"

class Hiera
  module Backend
    describe Aws::Base do
      let(:service) { Aws::Base.new  }

      describe "#lookup" do
        it "raises an exception when called with unhandled key" do
          expect do
            service.lookup("key_with_no_matching_method", {})
          end.to raise_error Aws::NoHandlerError
        end

        it "properly maps key to method and calls it" do
          service.should_receive(:some_key)
          service.lookup("some_key", {})
        end

        it "properly stores the scope (Puppet facts)" do
          scope = { "foo" => "bar" }
          service.stub(:some_key)
          service.lookup("some_key", scope)
          service.instance_variable_get("@scope").should eq scope
        end
      end
    end
  end
end
