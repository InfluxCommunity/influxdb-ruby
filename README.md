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

Write data via UDP:

``` ruby
require 'influxdb'
host = '127.0.0.1'
port = 4444

influxdb = InfluxDB::Client.new :udp => { :host => host, :port => port }

name = 'hitchhiker'

data = {
  :answer => 42,
  :question => "life the universe and everything?"
}

influxdb.write_point(name, data)
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

By default, an InfluxDB::Client will keep trying to connect to the database when
it gets connection denied, if you want to retry a finite number of times
(or disable retries altogether), you should pass the `:retry`
value. `:retry` can be either `true`, `false` or an `Integer` to retry
infinite times, disable retries or retry a finite number of times,
respectively. `0` is equivalent to `false`

```
> require 'influxdb'
=> true

> influxdb = InfluxDB::Client.new 'database', :retry => 4
=> #<InfluxDB::Client:0x00000002bb5ce0 @database="database", @hosts=["localhost"],
@port=8086, @username="root", @password="root", @use_ssl=false,
@time_precision="s", @initial_delay=0.01, @max_delay=30,
@open_timeout=5, @read_timeout=300, @async=false, @retry=4>

> influxdb.query 'select * from serie limit 1'
E, [2014-06-02T11:04:13.416209 #22825] ERROR -- : [InfluxDB] Failed to
contact host localhost: #<SocketError: getaddrinfo: Name or service not known> -
retrying in 0.01s.
E, [2014-06-02T11:04:13.433646 #22825] ERROR -- : [InfluxDB] Failed to
contact host localhost: #<SocketError: getaddrinfo: Name or service not known> -
retrying in 0.02s.
E, [2014-06-02T11:04:13.462566 #22825] ERROR -- : [InfluxDB] Failed to
contact host localhost: #<SocketError: getaddrinfo: Name or service not known> -
retrying in 0.04s.
E, [2014-06-02T11:04:13.510853 #22825] ERROR -- : [InfluxDB] Failed to
contact host localhost: #<SocketError: getaddrinfo: Name or service not known> -
retrying in 0.08s.
SocketError: Tried 4 times to reconnect but failed.

```
If you pass `:retry => -1` it will keep trying forever
until it gets the connection.

Testing
-------

```
git clone git@github.com:influxdb/influxdb-ruby.git
cd influxdb-ruby
bundle
bundle exec rake
```
