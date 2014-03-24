influxdb-ruby
=============

[![Build Status](https://travis-ci.org/influxdb/influxdb-ruby.png?branch=master)](https://travis-ci.org/influxdb/influxdb-ruby)

Ruby client library for [InfluxDB](http://influxdb.org/).

Install
-------

```
$ [sudo] gem install influxdb
```

Or add it to your `Gemfile`, etc.

Usage
-----

Connecting to a single host:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new host: "influxdb.domain.com"
```

Connecting to multiple hosts (with built-in load balancing and failover):

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new hosts: ["influxdb1.domain.com", "influxdb2.domain.com"]
```

Create a database:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.create_database(database)
```

Create a user for a database:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

database = 'site_development'
new_username = 'foo'
new_password = 'bar'
influxdb.create_database_user(database, new_username, new_password)
```

Update a database user:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.update_database_user(database, username, :password => "new_password")
```

Write some data:

``` ruby
require 'influxdb'

username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new database, :username => username, :password => password

# Enumerator that emits a sine wave
Value = (0..360).to_a.map {|i| Math.send(:sin, i / 10.0) * 10 }.each

loop do
  data = {
    :value => Value.next
  }

  influxdb.write_point(name, data)

  sleep 1
end
```

Write data with time precision:

Time precision can be set in 2 ways, either in the client initialization

``` ruby
require 'influxdb'

username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'
time_precision = 's'

influxdb = InfluxDB::Client.new database, :username => username,
                                          :password => password, 
                                          :time_precision => time_precision

data = {
  :value => 0,
  :time => Time.now.to_i
}

influxdb.write_point(name, data)
```
or in the write call

``` ruby
require 'influxdb'

username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'
time_precision = 's'

influxdb = InfluxDB::Client.new database, :username => username, :password => password

data = {
  :value => 0,
  :time => Time.now.to_i
}

influxdb.write_point(name, data, false, time_precision)
```


List cluster admins:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.get_cluster_admin_list
```

List databases:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.get_database_list
```

List database users:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.get_database_user_list(database)
```

List a database user:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.get_database_user_info(database, username)
```

Delete a database:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

database = 'site_development'
influxdb.delete_database(database)
```

Delete a database user:

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new

influxdb.delete_database_user(database, username)
```

Querying:

``` ruby
require 'influxdb'

username = 'foo'
password = 'bar'
database = 'site_development'

influxdb = InfluxDB::Client.new database, :username => username, :password => password

influxdb.query 'select * from time_series_1' do |name, points|
  puts "#{name} => #{points}"
end
```


Testing
-------

```
git clone git@github.com:influxdb/influxdb-ruby.git
cd influxdb-ruby
bundle
bundle exec rspec
```
