require "spec_helper"
require "json"

describe InfluxDB::Client do
  before do
    @influxdb = InfluxDB::Client.new "database", {
      :host => "influxdb.test", :port => 9999, :username => "username",
      :password => "password", :time_precision => "s" }.merge(args)
  end
  let(:args) { {} }

  describe "#new" do
    describe "with no parameters specified" do
      it "should be initialzed with a nil database and the default options" do
        @influxdb = InfluxDB::Client.new

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.hosts.should == ["localhost"]
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
        @influxdb.use_ssl.should be_falsey
        @influxdb.time_precision.should == "s"
        @influxdb.auth_method.should == "params"
      end
    end

    describe "with no database specified" do
      it "should be initialized with a nil database and the specified options" do
        @influxdb = InfluxDB::Client.new :host => "host",
                                         :port => "port",
                                         :username => "username",
                                         :password => "password",
                                         :time_precision => "m"

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.hosts.should == ["host"]
        @influxdb.port.should == "port"
        @influxdb.username.should == "username"
        @influxdb.password.should == "password"
        @influxdb.time_precision.should == "m"
      end
    end

    describe "with only a database specified" do
      it "should be initialized with the specified database and the default options" do
        @influxdb = InfluxDB::Client.new "database"

        @influxdb.should be_a(InfluxDB::Client)
        @influxdb.database.should == "database"
        @influxdb.hosts.should == ["localhost"]
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
        @influxdb.time_precision.should == "s"
      end
    end

    describe "with both a database and options specified" do
      it "should be initialized with the specified database and options" do
        @influxdb = InfluxDB::Client.new "database", :host => "host",
                                                     :port => "port",
                                                     :username => "username",
                                                     :password => "password",
                                                     :time_precision => "m"

        @influxdb.should be_a(InfluxDB::Client)
        @influxdb.database.should == "database"
        @influxdb.hosts.should == ["host"]
        @influxdb.port.should == "port"
        @influxdb.username.should == "username"
        @influxdb.password.should == "password"
        @influxdb.time_precision.should == "m"
      end
    end

    describe "with ssl option specified" do
      it "should be initialized with ssl enabled" do
        @influxdb = InfluxDB::Client.new :use_ssl => true

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.hosts.should == ["localhost"]
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
        @influxdb.use_ssl.should be_truthy
      end
    end

    describe "with multiple hosts specified" do
      it "should be initialized with ssl enabled" do
        @influxdb = InfluxDB::Client.new :hosts => ["1.1.1.1", "2.2.2.2"]

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.hosts.should == ["1.1.1.1", "2.2.2.2"]
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
      end
    end

    describe "with auth_method basic auth specified" do
      it "should be initialized with basic auth enabled" do
        @influxdb = InfluxDB::Client.new :auth_method => 'basic_auth'

        @influxdb.should be_a(InfluxDB::Client)
        @influxdb.auth_method.should == 'basic_auth'
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
      end
    end

    describe "with udp specified" do
      it "should initialize a udp client" do
        @influxdb = InfluxDB::Client.new :udp => { :host => 'localhost', :port => 4444 }
        expect(@influxdb.udp_client).to be_a(InfluxDB::UDPClient)
      end

      context "without udp specfied" do
        it "does not initialize a udp client" do
          @influxdb = InfluxDB::Client.new
          expect(@influxdb.udp_client).to be_nil
        end
      end
    end
  end


  context "with basic auth enabled" do
    let(:args) { { :auth_method => 'basic_auth' } }
    it "should use basic authorization for get" do
      stub_request(:get, "http://username:password@influxdb.test:9999/").to_return(:body => '[]')
      @influxdb.send(:get , @influxdb.send(:full_url,'/'), parse: true).should == []
    end
    it "should use basic authorization for post" do
      stub_request(:post, "http://username:password@influxdb.test:9999/")
      @influxdb.send(:post , @influxdb.send(:full_url,'/'), {}).should be_a(Net::HTTPOK)
    end
    it "should use basic authorization for delete" do
      stub_request(:delete, "http://username:password@influxdb.test:9999/")
      @influxdb.send(:delete , @influxdb.send(:full_url,'/')).should be_a(Net::HTTPOK)
    end
  end

  describe "#create_database" do
    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "CREATE DATABASE foo"}
      )
    end

    it "should GET to create a new database" do
      @influxdb.create_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_database" do
    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "DROP DATABASE foo"}
      )
    end

    it "should GET to remove a database" do
      @influxdb.delete_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#get_database_list" do
    let(:response) { {"results"=>[{"series"=>[{"name"=>"databases", "columns"=>["name"], "values"=>[["foobar"]]}]}]} }
    let(:expected_result) { [{"name"=>"foobar"}] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "SHOW DATABASES"}
      ).to_return(:body => JSON.generate(response), :status => 200)
    end

    it "should GET a list of databases" do
      @influxdb.get_database_list.should eq(expected_result)
    end
  end

  describe "#create_cluster_admin" do
    let(:user) { 'adminadmin' }
    let(:pass) { 'passpass' }
    let(:query) { "CREATE USER #{user} WITH PASSWORD '#{pass}' WITH ALL PRIVILEGES" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to create a new cluster admin" do
      @influxdb.create_cluster_admin(user, pass).should be_a(Net::HTTPOK)
    end
  end

  describe "#get_cluster_admin_list" do
    let(:response) { {"results"=>[{"series"=>[{"columns"=>["user", "admin"], "values"=>[["dbadmin", true], ["foobar", false]]}]}]} }
    let(:expected_result) { [{"username"=>"dbadmin"}] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "SHOW USERS"}
      ).to_return(:body => JSON.generate(response, :status => 200))
    end

    it "should GET a list of cluster admins" do
      @influxdb.get_cluster_admin_list.should eq(expected_result)
    end
  end

  describe "#create_database_user" do
    let(:user) { 'useruser' }
    let(:pass) { 'passpass' }
    let(:db) { 'foo' }
    let(:query) { "CREATE user #{user} WITH PASSWORD '#{pass}'; GRANT ALL ON #{db} TO #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    context "without specifying permissions" do
      it "should GET to create a new database user with all permissions" do
        @influxdb.create_database_user(db, user, pass).should be_a(Net::HTTPOK)
      end
    end

    context "with passing permission as argument" do
      let(:permission) { :read }
      let(:query) { "CREATE user #{user} WITH PASSWORD '#{pass}'; GRANT #{permission.to_s.upcase} ON #{db} TO #{user}" }

      it "should GET to create a new database user with permission set" do
        @influxdb.create_database_user(db, user, pass, permissions: permission).should be_a(Net::HTTPOK)
      end
    end
  end

  describe "#update user password" do
    let(:user) { 'useruser' }
    let(:pass) { 'passpass' }
    let(:query) { "SET PASSWORD FOR #{user} = '#{pass}'" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to update user password" do
      @influxdb.update_user_password(user, pass).should be_a(Net::HTTPOK)
    end
  end

  describe "#grant_user_privileges" do
    let(:user) { 'useruser' }
    let(:perm) { :write }
    let(:db) { 'foo' }
    let(:query) { "GRANT #{perm.to_s.upcase} ON #{db} TO #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to grant privileges for a user on a database" do
      @influxdb.grant_user_privileges(user, db, perm).should be_a(Net::HTTPOK)
    end
  end

  describe "#revoke_user_privileges" do
    let(:user) { 'useruser' }
    let(:perm) { :write }
    let(:db) { 'foo' }
    let(:query) { "REVOKE #{perm.to_s.upcase} ON #{db} FROM #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to revoke privileges from a user on a database" do
      @influxdb.revoke_user_privileges(user, db, perm).should be_a(Net::HTTPOK)
    end
  end

  describe "#revoke_cluster_admin_privileges" do
    let(:user) { 'useruser' }
    let(:query) { "REVOKE ALL PRIVILEGES FROM #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to revoke cluster admin privileges from a user" do
      @influxdb.revoke_cluster_admin_privileges(user).should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_user" do
    let(:user) { 'useruser' }
    let(:query) { "DROP USER #{user}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: query}
      )
    end

    it "should GET to delete a user" do
      @influxdb.delete_user(user).should be_a(Net::HTTPOK)
    end
  end

  describe "#get_user_list" do
    let(:response) { {"results"=>[{"series"=>[{"columns"=>["user", "admin"], "values"=>[["dbadmin", true], ["foobar", false]]}]}]} }
    let(:expected_result) { [{"username"=>"dbadmin", "admin"=>true}, {"username"=>"foobar", "admin"=>false}] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "SHOW USERS"}
      ).to_return(:body => JSON.generate(response, :status => 200))
    end

    it "should GET a list of database users" do
      @influxdb.get_user_list.should eq(expected_result)
    end
  end

  # describe "#get_shard_list" do
  #   it "should GET a list of shards" do
  #     shard_list = {"longTerm" => [], "shortTerm" => []}
  #     stub_request(:get, "http://influxdb.test:9999/cluster/shards").with(
  #       :query => {:u => "username", :p => "password"}
  #     ).to_return(:body => JSON.generate(shard_list, :status => 200))

  #     @influxdb.get_shard_list.should == shard_list
  #   end
  # end

  # describe "#delete_shard" do
  #   it "should DELETE a shard by id" do
  #     shard_id = 1
  #     stub_request(:delete, "http://influxdb.test:9999/cluster/shards/#{shard_id}").with(
  #       :query => {:u => "username", :p => "password"}
  #     )

  #     @influxdb.delete_shard(shard_id, [1, 2]).should be_a(Net::HTTPOK)
  #   end
  # end

  # describe "#delete_series" do
  #   it "should DELETE to remove a series" do
  #     stub_request(:delete, "http://influxdb.test:9999/db/database/series/foo").with(
  #       :query => {:u => "username", :p => "password"}
  #     )

  #     @influxdb.delete_series("foo").should be_a(Net::HTTPOK)
  #   end
  # end

  describe "#write_point" do
    let(:series) { "cpu" }
    let(:data) do
      { tags: { region: 'us', host: 'server_1' },
        values: { temp: 88,  value: 54 } }
    end
    let(:body) do
      InfluxDB::PointValue.new(data.merge(series: series)).dump
    end

    before do
      stub_request(:post, "http://influxdb.test:9999/write").with(
        :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        :headers => {"Content-Type" => "application/octet-stream"},
        :body => body
      )
    end

    it "should POST to add single point" do
      @influxdb.write_point(series, data).should be_a(Net::HTTPOK)
    end

    describe "retrying requests" do

      subject { @influxdb.write_point(series, data) }

      before do
        allow(@influxdb).to receive(:log)
        stub_request(:post, "http://influxdb.test:9999/write").with(
          :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
          :headers => {"Content-Type" => "application/octet-stream"},
          :body => body
        ).to_raise(Timeout::Error)
      end

      it "raises when stopped" do
        @influxdb.stop!
        @influxdb.should_not_receive :sleep
        expect { subject }.to raise_error(Timeout::Error)
      end

      context "when retry is 0" do
        let(:args) { { :retry => 0 } }
        it "raise error directly" do
          @influxdb.should_not_receive :sleep
          expect { subject }.to raise_error(Timeout::Error)
        end
      end

      context "when retry is 'n'" do
        let(:args) { { :retry => 3 } }

        it "raise error after 'n' attemps" do
          @influxdb.should_receive(:sleep).exactly(3).times
          expect { subject }.to raise_error(Timeout::Error)
        end
      end

      context "when retry is -1" do
        let(:args) { { :retry => -1 } }
        before do
          stub_request(:post, "http://influxdb.test:9999/write").with(
            :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
            :headers => {"Content-Type" => "application/octet-stream"},
            :body => body
          ).to_raise(Timeout::Error).then.to_raise(Timeout::Error).then.to_raise(Timeout::Error).then.to_raise(Timeout::Error).then.to_return(:status => 200)
        end

        it "keep trying until get the connection" do
          @influxdb.should_receive(:sleep).at_least(4).times
          expect { subject }.to_not raise_error
        end
      end
    end

    it "raise an exception if the server didn't return 200" do
      stub_request(:post, "http://influxdb.test:9999/write").with(
        :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        :headers => {"Content-Type" => "application/octet-stream"},
        :body => body
      ).to_return(:status => 401)

      expect { @influxdb.write_point(series, data) }.to raise_error
    end
  end

  describe "#write_points" do

    context "with multiple series" do
      let(:data) do
        [{
          series: 'cpu',
          tags: {  region: 'us', host: 'server_1' },
          values: { temp: 88, value: 54 }
        },
        {
          series: 'gpu',
          tags: { region: 'uk',  host: 'server_5'},
          values: { value: 0.5435345}
        }]
      end
      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
          :headers => {"Content-Type" => "application/octet-stream"},
          :body => body
      )
      end

      it "should POST multiple points" do
        @influxdb.write_points(data).should be_a(Net::HTTPOK)
      end
    end

    context "with no tags" do
      let(:data) do
        [{
          series: 'cpu',
          values: { temp: 88,  value: 54 }
        },
        {
          series: 'gpu',
          values: { value: 0.5435345 }
        }]
      end
      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          :query => {:u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
          :headers => {"Content-Type" => "application/octet-stream"},
          :body => body
        )
      end

      it "should POST multiple points" do
        @influxdb.write_points(data).should be_a(Net::HTTPOK)
      end
    end

    context "with time precision set to milisceconds" do
      let(:data) do
        [{
          series: 'cpu',
          values: { temp: 88,  value: 54 },
          timestamp: (Time.now.to_f * 1000).to_i
        },
        {
          series: 'gpu',
          values: { value: 0.5435345 },
          timestamp: (Time.now.to_f * 1000).to_i
        }]
      end

      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          :query => {:u => "username", :p => "password", :precision => 'm', :db => @influxdb.database},
          :headers => {"Content-Type" => "application/octet-stream"},
          :body => body
        )
      end
      it "should POST multiple points" do
        @influxdb.write_points(data, false, 'm').should be_a(Net::HTTPOK)
      end
    end

    context "with async client" do
      let(:data) do
        {
          series: 'cpu',
          values: { temp: 88,  value: 54 },
          tags: { foo: 'bar' }
        }
      end
      let(:point) { InfluxDB::PointValue.new(data).dump }

      it "should push to worker with payload" do
        @influxdb = InfluxDB::Client.new "database", :host => "influxdb.test", :async => true

        @influxdb.stub_chain(:worker, :push).with(point).and_return(:ok)
        @influxdb.write_points(data).should eq(:ok)
      end

      it "should push to the worker with payload if write_point call is async" do
        @influxdb = InfluxDB::Client.new "database", :host => "influxdb.test", :async => false

        @influxdb.stub_chain(:worker, :push).with(point).and_return(:ok)
        @influxdb.write_points(data, true).should eq(:ok)
      end
    end

    context "with udp client" do
      let(:data) do
        {
          series: 'cpu',
          values: { temp: 88,  value: 54 },
          tags: { foo: 'bar' }
        }
      end
      let(:point) { InfluxDB::PointValue.new(data).dump }
      let(:udp_client) { double }
      let(:time) { Time.now.to_i }
      let(:influxdb)  { InfluxDB::Client.new(:udp => { :host => "localhost", :port => 44444 }) }

      before do
        allow(InfluxDB::UDPClient).to receive(:new).with('localhost', 44444).and_return(udp_client)
      end

      it "should send payload via udp" do
        expect(udp_client).to receive(:send).with(point)
        influxdb.write_points(data)
      end
    end
  end


  describe "#query" do

    context "with single series with multiple points" do
      let(:response) do
        {"results"=>[{"series"=>[{"name"=>"cpu", "tags"=>{"region"=>"us"},
         "columns"=>["time", "temp", "value"],
         "values"=>[["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]]}]}]}
      end
      let(:expected_result) do
        [{"name"=>"cpu", "tags"=>{"region"=>"us"},
         "values"=>[{"time"=>"2015-07-07T14:58:37Z", "temp"=>92, "value"=>0.3445},
         {"time"=>"2015-07-07T14:59:09Z", "temp"=>68, "value"=>0.8787}]}]
      end
      let(:query) { 'SELECT * FROM cpu' }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          :query => {:q => query, :u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        ).to_return(:body => JSON.generate(response))
      end

      it "should return array with single hash containing multiple values" do
        @influxdb.query(query).should eq(expected_result)
      end
    end

    context "with series with different tags" do
      let(:response) do
        {"results"=>
          [{"series"=>
            [{"name"=>"cpu", "tags"=>{"region"=>"pl"}, "columns"=>["time", "temp", "value"], "values"=>[["2015-07-07T15:13:04Z", 34, 0.343443]]},
             {"name"=>"cpu", "tags"=>{"region"=>"us"}, "columns"=>["time", "temp", "value"], "values"=>[["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]]}]}]}
      end
      let(:expected_result) do
        [{"name"=>"cpu", "tags"=>{"region"=>"pl"},
         "values"=>[{"time"=>"2015-07-07T15:13:04Z", "temp"=>34, "value"=>0.343443}]},
         {"name"=>"cpu", "tags"=>{"region"=>"us"},
         "values"=>[{"time"=>"2015-07-07T14:58:37Z", "temp"=>92, "value"=>0.3445},
          {"time"=>"2015-07-07T14:59:09Z", "temp"=>68, "value"=>0.8787}]}]
      end
      let(:query) { 'SELECT * FROM cpu' }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          :query => {:q => query, :u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        ).to_return(:body => JSON.generate(response))
      end

      it "should return array with 2 elements grouped by tags" do
        @influxdb.query(query).should eq(expected_result)
      end
    end

    context "with multiple series with different tags" do
      let(:response) do
        {"results"=>
          [{"series"=>
            [{"name"=>"access_times.service_1", "tags"=>{"code"=>"200", "result"=>"failure", "status"=>"OK"}, "columns"=>["time", "value"], "values"=>[["2015-07-08T07:15:22Z", 327]]},
            {"name"=>"access_times.service_1", "tags"=>{"code"=>"500", "result"=>"failure", "status"=>"Internal Server Error"}, "columns"=>["time", "value"], "values"=>[["2015-07-08T06:15:22Z", 873]]},
            {"name"=>"access_times.service_2", "tags"=>{"code"=>"200", "result"=>"failure", "status"=>"OK"}, "columns"=>["time", "value"], "values"=>[["2015-07-08T07:15:22Z", 943]]},
            {"name"=>"access_times.service_2", "tags"=>{"code"=>"500", "result"=>"failure", "status"=>"Internal Server Error"}, "columns"=>["time", "value"], "values"=>[["2015-07-08T06:15:22Z", 606]]}]}]}
      end
      let(:expected_result) do
        [{"name"=>"access_times.service_1", "tags"=>{"code"=>"200", "result"=>"failure", "status"=>"OK"}, "values"=>[{"time"=>"2015-07-08T07:15:22Z", "value"=>327}]},
         {"name"=>"access_times.service_1", "tags"=>{"code"=>"500", "result"=>"failure", "status"=>"Internal Server Error"}, "values"=>[{"time"=>"2015-07-08T06:15:22Z", "value"=>873}]},
         {"name"=>"access_times.service_2", "tags"=>{"code"=>"200", "result"=>"failure", "status"=>"OK"}, "values"=>[{"time"=>"2015-07-08T07:15:22Z", "value"=>943}]},
         {"name"=>"access_times.service_2", "tags"=>{"code"=>"500", "result"=>"failure", "status"=>"Internal Server Error"}, "values"=>[{"time"=>"2015-07-08T06:15:22Z", "value"=>606}]}]
      end
      let(:query) { "SELECT * FROM /access_times.*/" }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          :query => {:q => query, :u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        ).to_return(:body => JSON.generate(response))
      end

      it "should return array with 4 elements grouped by name and tags" do
        @influxdb.query(query).should eq(expected_result)
      end
    end

    context "with multiple series for explicit value only" do
      let(:response) do
        {"results"=>
          [{"series"=>
             [{"name"=>"access_times.service_1", "columns"=>["time", "value"], "values"=>[["2015-07-08T06:15:22Z", 873], ["2015-07-08T07:15:22Z", 327]]},
              {"name"=>"access_times.service_2", "columns"=>["time", "value"], "values"=>[["2015-07-08T06:15:22Z", 606], ["2015-07-08T07:15:22Z", 943]]}]}]}
      end
      let(:expected_result) do
        [{"name"=>"access_times.service_1", "tags"=>nil, "values"=>[{"time"=>"2015-07-08T06:15:22Z", "value"=>873}, {"time"=>"2015-07-08T07:15:22Z", "value"=>327}]},
         {"name"=>"access_times.service_2", "tags"=>nil, "values"=>[{"time"=>"2015-07-08T06:15:22Z", "value"=>606}, {"time"=>"2015-07-08T07:15:22Z", "value"=>943}]}]
      end
      let(:query) { "SELECT value FROM /access_times.*/" }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          :query => {:q => query, :u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        ).to_return(:body => JSON.generate(response))
      end

      it "should return array with 2 elements grouped by name only and no tags" do
        @influxdb.query(query).should eq(expected_result)
      end
    end

    context "with a block" do
      let(:response) do
        {"results"=>
          [{"series"=>
            [{"name"=>"cpu", "tags"=>{"region"=>"pl"}, "columns"=>["time", "temp", "value"], "values"=>[["2015-07-07T15:13:04Z", 34, 0.343443]]},
             {"name"=>"cpu", "tags"=>{"region"=>"us"}, "columns"=>["time", "temp", "value"], "values"=>[["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]]}]}]}
      end

      let(:expected_result) do
        [{"name"=>"cpu", "tags"=>{"region"=>"pl"},
         "values"=>[{"time"=>"2015-07-07T15:13:04Z", "temp"=>34, "value"=>0.343443}]},
         {"name"=>"cpu", "tags"=>{"region"=>"us"},
         "values"=>[{"time"=>"2015-07-07T14:58:37Z", "temp"=>92, "value"=>0.3445},
          {"time"=>"2015-07-07T14:59:09Z", "temp"=>68, "value"=>0.8787}]}]
      end
      let(:query) { 'SELECT * FROM cpu' }

      before do
        stub_request(:get, "http://influxdb.test:9999/query").with(
          :query => {:q => query, :u => "username", :p => "password", :precision => 's', :db => @influxdb.database},
        ).to_return(:body => JSON.generate(response))
      end

      it "should accept a block and yield name, tags and points" do
        results = []
        @influxdb.query(query) do |name, tags, points|
          results << {'name' => name, 'tags' => tags, 'values' => points}
        end
        results.should eq(expected_result)
      end
    end
  end

  describe "#full_url" do
    it "should return String" do
      @influxdb.send(:full_url, "/unknown").should be_a String
    end

    it "should escape params" do
      url = @influxdb.send(:full_url, "/unknown", :value => ' !@#$%^&*()/\\_+-=?|`~')
      url.should include("value=+%21%40%23%24%25%5E%26%2A%28%29%2F%5C_%2B-%3D%3F%7C%60%7E")
    end
  end
end
