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

  describe "POST #create_database_user" do
    it "creates a new database user" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users").with(
        query: { u: "username", p: "password" },
        body: { name: "useruser", password: "passpass" }
      )

      expect(subject.create_database_user("foo", "useruser", "passpass")).to be_a(Net::HTTPOK)
    end

    it "creates a new database user with permissions" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users").with(
        query: { u: "username", p: "password" },
        body: { name: "useruser", password: "passpass", readFrom: "/read*/", writeTo: "/write*/" }
      )

      expect(
        subject.create_database_user(
          "foo",
          "useruser",
          "passpass",
          readFrom: "/read*/", writeTo: "/write*/"
        )).to be_a(Net::HTTPOK)
    end
  end

  describe "POST #update_database_user" do
    it "updates a database user" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users/useruser").with(
        query: { u: "username", p: "password" },
        body: { password: "passpass" }
      )

      expect(subject.update_database_user("foo", "useruser", password: "passpass"))
        .to be_a(Net::HTTPOK)
    end
  end

  describe "POST #alter_database_privilege" do
    it "alters privileges for a user on a database" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users/useruser").with(
        query: { u: "username", p: "password" }
      )

      expect(subject.alter_database_privilege("foo", "useruser", true)).to be_a(Net::HTTPOK)
      expect(subject.alter_database_privilege("foo", "useruser", false)).to be_a(Net::HTTPOK)
    end
  end

  describe "DELETE #delete_database_user" do
    it "removes a database user" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo/users/bar").with(
        query: { u: "username", p: "password" }
      )

      expect(subject.delete_database_user("foo", "bar")).to be_a(Net::HTTPOK)
    end
  end

  describe "GET #list_database_users" do
    it "returns a list of database users" do
      user_list = [{ "username" => "user1" }, { "username" => "user2" }]
      stub_request(:get, "http://influxdb.test:9999/db/foo/users").with(
        query: { u: "username", p: "password" }
      ).to_return(body: JSON.generate(user_list, status: 200))

      expect(subject.list_database_users("foo")).to eq user_list
    end
  end

  describe "GET #database_user_info" do
    it "should GET information about a database user" do
      user_info = { "name" => "bar", "isAdmin" => true }
      stub_request(:get, "http://influxdb.test:9999/db/foo/users/bar").with(
        query: { u: "username", p: "password" }
      ).to_return(body: JSON.generate(user_info, status: 200))

      expect(subject.database_user_info("foo", "bar")).to eq user_info
    end
  end

  describe "GET #authenticate_database_user" do
    it "return OK" do
      stub_request(:get, "http://influxdb.test:9999/db/foo/authenticate")
        .with(
          query: { u: "username", p: "password" }
        ).to_return(body: '', status: 200)

      expect(subject.authenticate_database_user("foo")).to be_a(Net::HTTPOK)
    end
  end
end
