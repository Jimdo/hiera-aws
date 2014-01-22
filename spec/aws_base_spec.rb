require "hiera/backend/aws/base"

class Hiera
  module Backend
    describe Aws::Base do
      let(:service) { Aws::Base.new  }

      describe "#lookup" do
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
    end
  end
end
