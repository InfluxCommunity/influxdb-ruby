require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:subject) do
    described_class.new(
      "database",
      {
        host: "influxdb.test",
        port: 9999,
        username: "username",
        password: "password",
        time_precision: "s"
      }.merge(args)
    )
  end

  let(:args) { {} }

  describe "#create_cluster_admin" do
    let(:user) { 'adminadmin' }
    let(:pass) { 'passpass' }
    let(:query) { "CREATE USER #{user} WITH PASSWORD '#{pass}' WITH ALL PRIVILEGES" }

    context 'with existing admin user' do
      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          query: { u: "username", p: "password", q: query }
        )
      end

      it "should GET to create a new cluster admin" do
        expect(subject.create_cluster_admin(user, pass)).to be_a(Net::HTTPOK)
      end
    end

    context 'with no admin user' do
      let(:args) { { auth_method: 'none' } }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          query: { q: query }
        )
      end

      it "should GET to create a new cluster admin" do
        expect(subject.create_cluster_admin(user, pass)).to be_a(Net::HTTPOK)
      end
    end
  end

  describe "#list_cluster_admins" do
    let(:response) do
      { "results" => [{ "statement_id" => 0,
                        "series" => [{ "columns" => %w(user admin), "values" => [["dbadmin", true], ["foobar", false]] }] }] }
    end
    let(:expected_result) { ["dbadmin"] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: "SHOW USERS" }
      ).to_return(body: JSON.generate(response, status: 200))
    end

    it "should GET a list of cluster admins" do
      expect(subject.list_cluster_admins).to eq(expected_result)
    end
  end

  describe "#revoke_cluster_admin_privileges" do
    let(:user) { 'useruser' }
    let(:query) { "REVOKE ALL PRIVILEGES FROM #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: query }
      )
    end

    it "should GET to revoke cluster admin privileges from a user" do
      expect(subject.revoke_cluster_admin_privileges(user)).to be_a(Net::HTTPOK)
    end
  end
end
