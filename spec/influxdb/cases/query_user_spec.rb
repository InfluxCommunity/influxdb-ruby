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
  let(:query) { nil }
  let(:response) { { "results" => [{ "statement_id" => 0 }] } }

  before do
    stub_request(:get, "http://influxdb.test:9999/query").with(
      query: { u: "username", p: "password", q: query }
    ).to_return(body: JSON.generate(response))
  end

  describe "#update user password" do
    let(:user) { 'useruser' }
    let(:pass) { 'passpass' }
    let(:query) { "SET PASSWORD FOR #{user} = '#{pass}'" }

    it "should GET to update user password" do
      expect(subject.update_user_password(user, pass)).to be_a(Net::HTTPOK)
    end
  end

  describe "#grant_user_privileges" do
    let(:user) { 'useruser' }
    let(:perm) { :write }
    let(:db) { 'foo' }
    let(:query) { "GRANT #{perm.to_s.upcase} ON #{db} TO #{user}" }

    it "should GET to grant privileges for a user on a database" do
      expect(subject.grant_user_privileges(user, db, perm)).to be_a(Net::HTTPOK)
    end
  end

  describe "#grant_user_admin_privileges" do
    let(:user) { 'useruser' }
    let(:query) { "GRANT ALL PRIVILEGES TO #{user}" }

    it "should GET to grant privileges for a user on a database" do
      expect(subject.grant_user_admin_privileges(user)).to be_a(Net::HTTPOK)
    end
  end

  describe "#revoke_user_privileges" do
    let(:user) { 'useruser' }
    let(:perm) { :write }
    let(:db) { 'foo' }
    let(:query) { "REVOKE #{perm.to_s.upcase} ON #{db} FROM #{user}" }

    it "should GET to revoke privileges from a user on a database" do
      expect(subject.revoke_user_privileges(user, db, perm)).to be_a(Net::HTTPOK)
    end
  end

  describe "#create_database_user" do
    let(:user) { 'useruser' }
    let(:pass) { 'passpass' }
    let(:db) { 'foo' }
    let(:query) { "CREATE user #{user} WITH PASSWORD '#{pass}'; GRANT ALL ON #{db} TO #{user}" }

    context "without specifying permissions" do
      it "should GET to create a new database user with all permissions" do
        expect(subject.create_database_user(db, user, pass)).to be_a(Net::HTTPOK)
      end
    end

    context "with passing permission as argument" do
      let(:permission) { :read }
      let(:query) { "CREATE user #{user} WITH PASSWORD '#{pass}'; GRANT #{permission.to_s.upcase} ON #{db} TO #{user}" }

      it "should GET to create a new database user with permission set" do
        expect(subject.create_database_user(db, user, pass, permissions: permission)).to be_a(Net::HTTPOK)
      end
    end
  end

  describe "#delete_user" do
    let(:user) { 'useruser' }
    let(:query) { "DROP USER #{user}" }

    it "should GET to delete a user" do
      expect(subject.delete_user(user)).to be_a(Net::HTTPOK)
    end
  end

  describe "#list_users" do
    let(:query) { "SHOW USERS" }
    let(:response) { { "results" => [{ "statement_id" => 0, "series" => [{ "columns" => %w(user admin), "values" => [["dbadmin", true], ["foobar", false]] }] }] } }
    let(:expected_result) { [{ "username" => "dbadmin", "admin" => true }, { "username" => "foobar", "admin" => false }] }

    it "should GET a list of database users" do
      expect(subject.list_users).to eq(expected_result)
    end
  end

  describe "#list_user_grants" do
    let(:user) { 'useruser' }
    let(:list_query) { "SHOW GRANTS FOR #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query")
        .with(query: { u: "username", p: "password", q: list_query })
        .to_return(status: 200, body: "", headers: {})
    end

    it "should GET for a user" do
      expect(subject.list_user_grants(user)).to be_a(Net::HTTPOK)
    end
  end
end
