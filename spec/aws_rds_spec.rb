require "hiera/backend/aws/rds"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::RDS do
      let(:rds) { Aws::RDS.new }
      let(:rds_client) do
        double(
          :describe_db_instances => {
            :db_instances => [
              {
                :db_instance_identifier => "db1",
                :endpoint => { :address => "db1.eu-west-1.rds.amazonaws.com" }
              },
              {
                :db_instance_identifier => "db2",
                :endpoint => { :address => "db2.eu-west-1.rds.amazonaws.com" }
              },
              {
                :db_instance_identifier => "db3",
                :endpoint => { :address => "db3.eu-west-1.rds.amazonaws.com" }
              }
            ]
          }
        )
      end
      let(:rds_tags) do
        {
          "arn:aws:rds:eu-west-1:12345678:db:db1" => {
            :tag_list => [
              { :key => "environment", :value => "dev" }
            ]
          },
          "arn:aws:rds:eu-west-1:12345678:db:db2" => {
            :tag_list => [
              { :key => "environment", :value => "dev" },
              { :key => "role", :value => "mgmt-db" }
            ]
          },
          "arn:aws:rds:eu-west-1:12345678:db:db3" => {
            :tag_list => [
              { :key => "environment", :value => "production" },
              { :key => "role", :value => "mgmt-db" }
            ]
          }

        }
      end

      before do
        AWS::RDS::Client.stub(:new => rds_client)
        rds_client.stub(:list_tags_for_resource) { |options| rds_tags[options[:resource_name]] }
      end

      describe "#lookup" do
        it "returns nil if Hiera key is unknown" do
          expect(rds.lookup("doge")).to be_nil
        end

        it "returns all database instances if no tags are provided" do
          expect(rds.lookup("rds")).to eq ["db1.eu-west-1.rds.amazonaws.com", "db2.eu-west-1.rds.amazonaws.com", "db3.eu-west-1.rds.amazonaws.com"]
        end

        it "returns database instances with specific tags" do
          expect(rds.lookup("rds role=mgmt-db")).to eq ["db2.eu-west-1.rds.amazonaws.com", "db3.eu-west-1.rds.amazonaws.com"]
          expect(rds.lookup("rds environment=dev")).to eq ["db1.eu-west-1.rds.amazonaws.com", "db2.eu-west-1.rds.amazonaws.com"]
          expect(rds.lookup("rds environment=production role=mgmt-db")).to eq ["db3.eu-west-1.rds.amazonaws.com"]
        end
      end
    end
  end
end
