# TODO: support 0.9.x

# require "spec_helper"
# require "json"

# describe InfluxDB::Client do
#   let(:subject) do
#     described_class.new(
#       "database",
#       {
#         host: "influxdb.test",
#         port: 9999,
#         username: "username",
#         password: "password",
#         time_precision: "s"
#       }.merge(args)
#     )
#   end

#   let(:args) { {} }

#   let(:url) { "http://influxdb.test:9999/cluster/shard_spaces" }
#   let(:req_query) { { u: "username", p: "password" } }
#   let(:req_body) { nil }
#   let(:request_params) { { query: req_query, body: req_body } }
#   let(:response) { { body: JSON.generate(shard_spaces), status: 200 } }
#   let(:shard_spaces)   { [subject.default_shard_space_options.merge("database" => "foo")] }

#   context "GET methods" do
#     before { stub_request(:get, url).with(request_params).to_return(response) }

#     describe "GET #list_shard_spaces" do
#       it 'returns OK' do
#         expect(subject.list_shard_spaces).to eq shard_spaces
#       end
#     end

#     describe "GET #shard_space_info" do
#       context "non-empty list" do
#         it "returns shard space info" do
#           expect(subject.shard_space_info('foo', 'default')).to eq shard_spaces.first
#         end
#       end

#       context "returns an empty list" do
#         let(:shard_spaces) { [] }

#         it "returns no shard space" do
#           expect(subject.shard_space_info('foo', 'default')).to be_nil
#         end
#       end
#     end
#   end

#   describe "POST #create_shard_space" do
#     let(:url) { "http://influxdb.test:9999/cluster/shard_spaces/foo" }
#     let(:req_body) { subject.default_shard_space_options }
#     let(:response) { { status: 200 } }

#     before { stub_request(:post, url).with(request_params).to_return(response) }

#     it 'returns OK' do
#       expect(subject.create_shard_space("foo", subject.default_shard_space_options))
#         .to be_a(Net::HTTPOK)
#     end
#   end

#   describe "DELETE #delete_shard_space" do
#     let(:url) { "http://influxdb.test:9999/cluster/shard_spaces/foo/default" }
#     let(:response) { { status: 200 } }
#     before { stub_request(:delete, url).with(request_params).to_return(response) }

#     it 'returns OK' do
#       expect(subject.delete_shard_space("foo", "default")).to be_a(Net::HTTPOK)
#     end
#   end

#   describe "#update_shard_space" do
#     let(:post_url) { "http://influxdb.test:9999/cluster/shard_spaces/foo/default" }
#     let(:post_request_params) do
#       {
#         query: req_query,
#         body:  subject.default_shard_space_options.merge("shardDuration" => "30d")
#       }
#     end

#     it 'gets the shard space and updates the shard space' do
#       stub_request(:get, url).with(request_params).to_return(response)
#       stub_request(:post, post_url).with(post_request_params)

#       expect(subject.update_shard_space("foo", "default", "shardDuration" => "30d")).to be_a(Net::HTTPOK)
#     end
#   end

#   describe "POST #configure_database" do
#     let(:url) { "http://influxdb.test:9999/cluster/database_configs/foo" }
#     let(:req_body) { subject.default_database_configuration }

#     before { stub_request(:post, url).with(request_params) }

#     it "returns OK" do
#       expect(subject.configure_database("foo")).to be_a(Net::HTTPOK)
#     end
#   end
# end
