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

  describe "POST #create_cluster_admin" do
    it "creates a new cluster admin" do
      stub_request(:post, "http://influxdb.test:9999/cluster_admins").with(
        query: { u: "username", p: "password" },
        body: { name: "adminadmin", password: "passpass" }
      )

      expect(subject.create_cluster_admin("adminadmin", "passpass")).to be_a(Net::HTTPOK)
    end
  end

  describe "POST #update_cluster_admin" do
    it "updates a cluster admin" do
      stub_request(:post, "http://influxdb.test:9999/cluster_admins/adminadmin").with(
        query: { u: "username", p: "password" },
        body: { password: "passpass" }
      )

      expect(subject.update_cluster_admin("adminadmin", "passpass")).to be_a(Net::HTTPOK)
    end
  end

  describe "DELETE #delete_cluster_admin" do
    it "deletes cluster admin" do
      stub_request(:delete, "http://influxdb.test:9999/cluster_admins/adminadmin").with(
        query: { u: "username", p: "password" }
      )

      expect(subject.delete_cluster_admin("adminadmin")).to be_a(Net::HTTPOK)
    end
  end

  describe "GET #list_cluster_admins" do
    it "return a list of cluster admins" do
      admin_list = [{ "username" => "root" }, { "username" => "admin" }]
      stub_request(:get, "http://influxdb.test:9999/cluster_admins").with(
        query: { u: "username", p: "password" }
      ).to_return(body: JSON.generate(admin_list), status: 200)

      expect(subject.list_cluster_admins).to eq admin_list
    end
  end

  describe "GET #authenticate_cluster_admin" do
    it "returns OK" do
      stub_request(:get, "http://influxdb.test:9999/cluster_admins/authenticate")
        .with(
          query:  { u: "username", p: "password" }
        )

      expect(subject.authenticate_cluster_admin).to be_a(Net::HTTPOK)
    end
  end
end
