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
      @influxdb.send(:get , @influxdb.send(:full_url,'/')).should == []
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
    it "should POST to create a new database" do
      stub_request(:post, "http://influxdb.test:9999/db").with(
        :query => {:u => "username", :p => "password"},
        :body => {:name => "foo"}
      )

      @influxdb.create_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_database" do
    it "should DELETE to remove a database" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#get_database_list" do
    it "should GET a list of databases" do
      database_list = [{"name" => "foobar"}]
      stub_request(:get, "http://influxdb.test:9999/db").with(
        :query => {:u => "username", :p => "password"}
      ).to_return(:body => JSON.generate(database_list), :status => 200)

      @influxdb.get_database_list.should == database_list
    end
  end

  describe "#create_cluster_admin" do
    it "should POST to create a new cluster admin" do
      stub_request(:post, "http://influxdb.test:9999/cluster_admins").with(
        :query => {:u => "username", :p => "password"},
        :body => {:name => "adminadmin", :password => "passpass"}
      )

      @influxdb.create_cluster_admin("adminadmin", "passpass").should be_a(Net::HTTPOK)
    end
  end

  describe "#update_cluster_admin" do
    it "should POST to update a cluster admin" do
      stub_request(:post, "http://influxdb.test:9999/cluster_admins/adminadmin").with(
        :query => {:u => "username", :p => "password"},
        :body => {:password => "passpass"}
      )

      @influxdb.update_cluster_admin("adminadmin", "passpass").should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_cluster_admin" do
    it "should DELETE a cluster admin" do
      stub_request(:delete, "http://influxdb.test:9999/cluster_admins/adminadmin").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_cluster_admin("adminadmin").should be_a(Net::HTTPOK)
    end
  end

  describe "#get_cluster_admin_list" do
    it "should GET a list of cluster admins" do
      admin_list = [{"username"=>"root"}, {"username"=>"admin"}]
      stub_request(:get, "http://influxdb.test:9999/cluster_admins").with(
        :query => {:u => "username", :p => "password"}
      ).to_return(:body => JSON.generate(admin_list), :status => 200)

      @influxdb.get_cluster_admin_list.should == admin_list
    end
  end

  describe "#create_database_user" do
    it "should POST to create a new database user" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users").with(
        :query => {:u => "username", :p => "password"},
        :body => {:name => "useruser", :password => "passpass"}
      )

      @influxdb.create_database_user("foo", "useruser", "passpass").should be_a(Net::HTTPOK)
    end
  end

  describe "#update_database_user" do
    it "should POST to update a database user" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users/useruser").with(
        :query => {:u => "username", :p => "password"},
        :body => {:password => "passpass"}
      )

      @influxdb.update_database_user("foo", "useruser", :password => "passpass").should be_a(Net::HTTPOK)
    end
  end

  describe "#alter_database_privilege" do
    it "should POST to alter privileges for a user on a database" do
      stub_request(:post, "http://influxdb.test:9999/db/foo/users/useruser").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.alter_database_privilege("foo", "useruser", admin=true).should be_a(Net::HTTPOK)
      @influxdb.alter_database_privilege("foo", "useruser", admin=false).should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_database_user" do
    it "should DELETE a database user" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo/users/bar").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_database_user("foo", "bar").should be_a(Net::HTTPOK)
    end
  end

  describe "#get_database_user_list" do
    it "should GET a list of database users" do
      user_list = [{"username"=>"user1"}, {"username"=>"user2"}]
      stub_request(:get, "http://influxdb.test:9999/db/foo/users").with(
        :query => {:u => "username", :p => "password"}
      ).to_return(:body => JSON.generate(user_list, :status => 200))

      @influxdb.get_database_user_list("foo").should == user_list
    end
  end

  describe "#get_database_user_info" do
    it "should GET information about a database user" do
      user_info = {"name" => "bar", "isAdmin" => true}
      stub_request(:get, "http://influxdb.test:9999/db/foo/users/bar").with(
        :query => {:u => "username", :p => "password"}
      ).to_return(:body => JSON.generate(user_info, :status => 200))

      @influxdb.get_database_user_info("foo", "bar").should == user_info
    end
  end

  describe "#get_shard_list" do
    it "should GET a list of shards" do
      shard_list = {"longTerm" => [], "shortTerm" => []}
      stub_request(:get, "http://influxdb.test:9999/cluster/shards").with(
        :query => {:u => "username", :p => "password"}
      ).to_return(:body => JSON.generate(shard_list, :status => 200))

      @influxdb.get_shard_list.should == shard_list
    end
  end

  describe "#delete_shard" do
    it "should DELETE a shard by id" do
      shard_id = 1
      stub_request(:delete, "http://influxdb.test:9999/cluster/shards/#{shard_id}").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_shard(shard_id, [1, 2]).should be_a(Net::HTTPOK)
    end
  end

  describe "#write_point" do
    it "should POST to add points" do
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      )

      data = {:name => "juan", :age => 87}

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    describe "retrying requests" do
      let(:body) do
        [{
             "name" => "seriez",
             "points" => [[87, "juan"]],
             "columns" => ["age", "name"]
         }]
      end

      let(:data) { {:name => "juan", :age => 87} }

      subject { @influxdb.write_point("seriez", data) }

      before do
        allow(@influxdb).to receive(:log)
        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
            :query => {:u => "username", :p => "password", :time_precision => "s"},
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
          stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
            :query => {:u => "username", :p => "password", :time_precision => "s"},
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
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      ).to_return(:status => 401)

      data = {:name => "juan", :age => 87}

      expect { @influxdb.write_point("seriez", data) }.to raise_error
    end

    it "should POST multiple points" do
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"], [99, "shahid"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      ).to_return(:status => 200)

      data = [{:name => "juan", :age => 87}, { :name => "shahid", :age => 99}]

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    it "should POST multiple points with missing columns" do
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"], [nil, "shahid"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      )

      data = [{:name => "juan", :age => 87}, { :name => "shahid"}]

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    it "should dump a hash point value to json" do
      prefs = [{'favorite_food' => 'lasagna'}]
      body = [{
        "name" => "users",
        "points" => [[1, prefs.to_json]],
        "columns" => ["id", "prefs"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      )

      data = {:id => 1, :prefs => prefs}

      @influxdb.write_point("users", data).should be_a(Net::HTTPOK)
    end

    it "should dump an array point value to json" do
      line_items = [{'id' => 1, 'product_id' => 2, 'quantity' => 1, 'price' => "100.00"}]
      body = [{
        "name" => "seriez",
        "points" => [[1, line_items.to_json]],
        "columns" => ["id", "line_items"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      )

      data = {:id => 1, :line_items => line_items}

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    it "should POST to add points with time field with precision defined in client initialization" do
      time_in_seconds = Time.now.to_i
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan", time_in_seconds]],
        "columns" => ["age", "name", "time"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "s"},
        :body => body
      )

      data = {:name => "juan", :age => 87, :time => time_in_seconds}

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    it "should POST to add points with time field with precision defined in call of write function" do
      time_in_milliseconds = (Time.now.to_f * 1000).to_i
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan", time_in_milliseconds]],
        "columns" => ["age", "name", "time"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password", :time_precision => "m"},
        :body => body
      )

      data = {:name => "juan", :age => 87, :time => time_in_milliseconds}

      @influxdb.write_point("seriez", data, false, "m").should be_a(Net::HTTPOK)
    end

    describe "async" do

      it "should push to the worker with payload if client is async" do
        @influxdb = InfluxDB::Client.new "database", :host => "influxdb.test", :async => true

        data = {:name => "juan", :age => 87, :time => Time.now.to_i}
        @influxdb.stub_chain(:worker, :push).with(hash_including({:name => 'seriez'})).and_return(:ok)
        @influxdb.write_point("seriez", data).should eq(:ok)
      end

      it "should push to the worker with payload if write_point call is async" do
        @influxdb = InfluxDB::Client.new "database", :host => "influxdb.test", :async => false

        data = {:name => "juan", :age => 87, :time => Time.now.to_i}
        @influxdb.stub_chain(:worker, :push).with(hash_including({:name => 'seriez'})).and_return(:ok)
        @influxdb.write_point("seriez", data, true).should eq(:ok)
      end

    end

    describe "udp" do
      let(:udp_client) { double }
      let(:time) { Time.now.to_i }
      let(:influxdb)  { InfluxDB::Client.new(:udp => { :host => "localhost", :port => 44444 }) }

      before do
        allow(InfluxDB::UDPClient).to receive(:new).with('localhost', 44444).and_return(udp_client)
      end

      it "should send payload via udp if udp client is set up" do
        expect(udp_client).to receive(:send).with([{:name=>"seriez", :points=>[[87, "juan", time]], :columns=>[:age, :name, :time]}])
        data = {:name => "juan", :age => 87, :time => time}
        influxdb.write_point("seriez", data)
      end
    end

  end

  describe "#execute_queries" do
    before(:each) do
      data = [{ :name => "foo", :columns => ["name", "age", "count", "count"], :points => [["shahid", 99, 1, 2],["dix", 50, 3, 4]]}]

      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        :query => { :q => "select * from foo", :u => "username", :p => "password", :time_precision => "s"}
      ).to_return(
        :body => JSON.generate(data)
      )
    end

    expected_series = { 'foo' => [{"name" => "shahid", "age" => 99, "count" => 1, "count~1" => 2}, {"name" => "dix", "age" => 50, "count" => 3, "count~1" => 4}]}

    it 'can execute a query with a block' do
      series = { }

      @influxdb.query "select * from foo" do |name, points|
        series[name] = points
      end

      series.should ==(expected_series)
    end

    it 'can execute a query without a block' do
      series = @influxdb.query 'select * from foo'
      series.should ==(expected_series)
    end
  end

  describe "#query" do

    it 'should load JSON point value as an array of hashes' do
      line_items = [{'id' => 1, 'product_id' => 2, 'quantity' => 1, 'price' => "100.00"}]

      data = [{ :name => "orders", :columns => ["id", "line_items"], :points => [[1, line_items.to_json]]}]

      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        :query => { :q => "select * from orders", :u => "username", :p => "password", :time_precision => "s"}
      ).to_return(
        :body => JSON.generate(data)
      )

      @influxdb.query('select * from orders').should == {'orders' => [{'id' => 1, 'line_items' => line_items}]}
    end
  end

  describe "#delete_series" do
    it "should DELETE to remove a series" do
      stub_request(:delete, "http://influxdb.test:9999/db/database/series/foo").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_series("foo").should be_a(Net::HTTPOK)
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
