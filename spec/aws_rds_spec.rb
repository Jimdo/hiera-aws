require "hiera/backend/aws/rds"

class Hiera
  module Backend # rubocop:disable Documentation
    describe Aws::RDS do
      let(:rds) { Aws::RDS.new }
      let(:rds_instances) do
        {
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
        rds_client = double
        AWS::RDS::Client.stub(:new).and_return(rds_client)
        allow(rds_client).to receive(:describe_db_instances).and_return(rds_instances)
        allow(rds_client).to receive(:list_tags_for_resource) do |options|
          rds_tags.fetch(options[:resource_name])
        end
      end

      describe "#lookup" do
        let(:scope) { { "aws_account_number" => "12345678" } }

        it "returns nil if Hiera key is unknown" do
          expect(rds.lookup("doge", scope)).to be_nil
        end

        it "returns all database instances if no tags are provided" do
          expect(rds.lookup("rds", scope)).to eq [
            {
              "db_instance_identifier" => "db1",
              "endpoint" => { "address" => "db1.eu-west-1.rds.amazonaws.com" }
            },
            {
              "db_instance_identifier" => "db2",
              "endpoint" => { "address" => "db2.eu-west-1.rds.amazonaws.com" }
            },
            {
              "db_instance_identifier" => "db3",
              "endpoint" => { "address" => "db3.eu-west-1.rds.amazonaws.com" }
            }
          ]
        end

        it "returns database instances with role tag" do
          expect(rds.lookup("rds role=mgmt-db", scope)).to eq [
            {
              "db_instance_identifier" => "db2",
              "endpoint" => { "address" => "db2.eu-west-1.rds.amazonaws.com" }
            },
            {
              "db_instance_identifier" => "db3",
              "endpoint" => { "address" => "db3.eu-west-1.rds.amazonaws.com" }
            }
          ]
        end

        it "returns database instances with environment tag" do
          expect(rds.lookup("rds environment=dev", scope)).to eq [
            {
              "db_instance_identifier" => "db1",
              "endpoint" => { "address" => "db1.eu-west-1.rds.amazonaws.com" }
            },
            {
              "db_instance_identifier" => "db2",
              "endpoint" => { "address" => "db2.eu-west-1.rds.amazonaws.com" }
            }
          ]
        end

        it "returns database instances with environment and role tags" do
          expect(rds.lookup("rds environment=production role=mgmt-db", scope)).to eq [
            {
              "db_instance_identifier" => "db3",
              "endpoint" => { "address" => "db3.eu-west-1.rds.amazonaws.com" }
            }
          ]
        end

        it "returns empty array if no database instances can be found" do
          expect(rds.lookup("rds environment=staging", scope)).to eq []
        end
      end
    end
  end
end
