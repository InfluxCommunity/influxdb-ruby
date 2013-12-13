require "spec_helper"
require "json"

describe InfluxDB::Client do
  before do
    @influxdb = InfluxDB::Client.new "database", :host => "influxdb.test",
      :port => 9999, :username => "username", :password => "password"
  end

  describe "#new" do
    describe "with no parameters specified" do
      it "should be initialzed with a nil database and the default options" do
        @influxdb = InfluxDB::Client.new

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.host.should == "localhost"
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
        @influxdb.should_not be_async
        @influxdb.queue.should == nil
      end

      it "should not spawn threads" do
        InfluxDB::Client.any_instance.should_not_receive(:spawn_threads!)
        @influxdb = InfluxDB::Client.new
      end
    end

    describe "with no database specified" do
      it "should be initialized with a nil database and the specified options" do
        @influxdb = InfluxDB::Client.new :hostname => "host",
                                         :port => "port",
                                         :username => "username",
                                         :password => "password"

        @influxdb.should be_a InfluxDB::Client
        @influxdb.database.should be_nil
        @influxdb.host.should == "localhost"
        @influxdb.port.should == "port"
        @influxdb.username.should == "username"
        @influxdb.password.should == "password"
      end
    end

    describe "with only a database specified" do
      it "should be initialized with the specified database and the default options" do
        @influxdb = InfluxDB::Client.new "database"

        @influxdb.should be_a(InfluxDB::Client)
        @influxdb.database.should == "database"
        @influxdb.host.should == "localhost"
        @influxdb.port.should == 8086
        @influxdb.username.should == "root"
        @influxdb.password.should == "root"
      end
    end

    describe "with both a database and options specified" do
      it "should be initialized with the specified database and options" do
        @influxdb = InfluxDB::Client.new "database", :hostname => "host",
                                                     :port => "port",
                                                     :username => "username",
                                                     :password => "password"

        @influxdb.should be_a(InfluxDB::Client)
        @influxdb.database.should == "database"
        @influxdb.host.should == "localhost"
        @influxdb.port.should == "port"
        @influxdb.username.should == "username"
        @influxdb.password.should == "password"
      end
    end

    describe "with async enabled" do
      it "should be async" do
        @influxdb = InfluxDB::Client.new nil, :async => true
        @influxdb.should be_async
      end

      it "should create queue" do
        @influxdb = InfluxDB::Client.new nil, :async => true
        @influxdb.should be_a InfluxDB::Client
        @influxdb.queue.should_not be_nil
      end

      it "should spawn threads" do
        InfluxDB::Client.any_instance.should_receive(:spawn_threads!)
        @influxdb = InfluxDB::Client.new nil, :async => true
      end
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

  describe "#write_point" do
    it "should POST to add points" do
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password"},
        :body => body
      )

      data = {:name => "juan", :age => 87}

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end

    it "raise an exception if the server didn't return 200" do
      body = [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => ["age", "name"]
      }]

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password"},
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
        :query => {:u => "username", :p => "password"},
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
        :query => {:u => "username", :p => "password"},
        :body => body
      )

      data = [{:name => "juan", :age => 87}, { :name => "shahid"}]

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end
  end

  describe "#execute_queries" do
    before(:each) do
      data = [{ :name => "foo", :columns => ["name", "age"], :points => [["shahid", 99],["dix", 50]]}]

      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        :query => { :q => "select * from foo", :u => "username", :p => "password"}
      ).to_return(
        :body => JSON.generate(data)
      )
    end

    expected_series = { 'foo' => [{"name" => "shahid", "age" => 99}, {"name" => "dix", "age" => 50}]}

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
end
