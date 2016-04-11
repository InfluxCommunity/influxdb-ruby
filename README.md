influxdb-ruby
=============

[![Build Status](https://travis-ci.org/influxdb/influxdb-ruby.png?branch=master)](https://travis-ci.org/influxdb/influxdb-ruby)

The official ruby client library for [InfluxDB](https://influxdb.com/). Maintained by [@toddboom](https://github.com/toddboom).

> **Support for InfluxDB v0.8.x is now deprecated**. The final version of this library that will support the older InfluxDB interface is `v0.1.9`, which is available as a gem and tagged on this repository. If you're reading this message, then you should only expect support for InfluxDB v0.9.1 and higher.

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
# or
influxdb = InfluxDB::Client.new  # no host given defaults connecting to localhost
```

Connecting to multiple hosts (with built-in load balancing and failover):

``` ruby
require 'influxdb'

influxdb = InfluxDB::Client.new hosts: ["influxdb1.domain.com", "influxdb2.domain.com"]
```

Create a database:

``` ruby
database = 'site_development'

influxdb.create_database(database)
```

Delete a database:

``` ruby
database = 'site_development'

influxdb.delete_database(database)
```

List databases:

``` ruby
influxdb.list_databases
```

Create a user for a database:

``` ruby
database = 'site_development'
new_username = 'foo'
new_password = 'bar'
permission = :write

# with all permissions
influxdb.create_database_user(database, new_username, new_password)

# with specified permission - options are: :read, :write, :all
influxdb.create_database_user(database, new_username, new_password, permissions: permission)
```

Update a user password:

``` ruby
username = 'foo'
new_password = 'bar'

influxdb.update_user_password(username, new_password)
```

Grant user privileges on database:

``` ruby
username = 'foobar'
database = 'foo'
permission = :read # options are :read, :write, :all

influxdb.grant_user_privileges(username, database, permission)
```

Revoke user privileges from database:

``` ruby
username = 'foobar'
database = 'foo'
permission = :write # options are :read, :write, :all

influxdb.revoke_user_privileges(username, database, permission)
```
Delete a user:

``` ruby
username = 'foobar'

influxdb.delete_user(username)
```

List users:

``` ruby
influxdb.list_users
```

Create cluster admin:

``` ruby
username = 'foobar'
password = 'pwd'

influxdb.create_cluster_admin(username, password)
```

List cluster admins:

``` ruby
influxdb.list_cluster_admins
```

Revoke cluster admin privileges from user:

``` ruby
username = 'foobar'

influxdb.revoke_cluster_admin_privileges(username)
```

List continuous queries of a database:

``` ruby
database = 'foo'

influxdb.list_continuous_queries(database)
```

Create a continuous query for a database:

``` ruby
database = 'foo'
name = 'clicks_count'
query = 'SELECT COUNT(name) INTO clicksCount_1h FROM clicks GROUP BY time(1h)'

influxdb.create_continuous_query(name, database, query)
```

Delete a continuous query from a database:

``` ruby
database = 'foo'
name = 'clicks_count'

influxdb.delete_continuous_query(name, database)
```

List retention policies of a database:

``` ruby
database = 'foo'

influxdb.list_retention_policies(database)
```

Create a retention policy for a database:

``` ruby
database = 'foo'
name = '1h.cpu'
duration = '10m'
replication = 2

influxdb.create_retention_policy(name, database, duration, replication)
```

Delete a retention policy from a database:

``` ruby
database = 'foo'
name = '1h.cpu'

influxdb.delete_retention_policy(name, database)
```

Alter a retention policy for a database:

``` ruby
database = 'foo'
name = '1h.cpu'
duration = '10m'
replication = 2

influxdb.alter_retention_policy(name, database, duration, replication)
```

Write some data:

``` ruby
username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new database,
                                username: username,
                                password: password

# Enumerator that emits a sine wave
Value = (0..360).to_a.map {|i| Math.send(:sin, i / 10.0) * 10 }.each

loop do
  data = {
    values: { value: Value.next },
    tags: { wave: 'sine' } # tags are optional
  }

  influxdb.write_point(name, data)

  sleep 1
end
```

Write data with time precision (precision can be set in 2 ways):

``` ruby
require 'influxdb'

username       = 'foo'
password       = 'bar'
database       = 'site_development'
name           = 'foobar'
time_precision = 's'

# either in the client initialization:
influxdb = InfluxDB::Client.new database, username: username,
                                          password: password,
                                          time_precision: time_precision

data = {
  values: { value: 0 },
  timestamp: Time.now.to_i # timestamp is optional, if not provided point will be saved with current time
}

influxdb.write_point(name, data)

# or in a method call:
influxdb.write_point(name, data, time_precision)

```

Write data with a specific retention policy:

``` ruby
require 'influxdb'

username  = 'foo'
password  = 'bar'
database  = 'site_development'
name      = 'foobar'
precision = 's'
retention = '1h.cpu'

influxdb = InfluxDB::Client.new database,
                                username: username,
                                password: password

data = {
  values: { value: 0 },
  tags: { foo: 'bar', bar: 'baz' }
  timestamp: Time.now.to_i
}

influxdb.write_point(name, data, precision, retention)
```

Write multiple points in a batch (performance boost):

``` ruby

data = [
  {
    series: 'cpu',
    tags: { host: 'server_1', region: 'us' },
    values: {internal: 5, external: 0.453345}
  },
  {
    series: 'gpu',
    values: {value: 0.9999},
  }
]

influxdb.write_points(data)

# you can also specify precision in method call

precision = 'm'
influxdb.write_points(data, precision)

```

Write multiple points in a batch with a specific retention policy:

``` ruby

data = [
  {
    series: 'cpu',
    tags: { host: 'server_1', region: 'us' },
    values: {internal: 5, external: 0.453345}
  },
  {
    series: 'gpu',
    values: {value: 0.9999},
  }
]

precision = 'm'
retention = '1h.cpu'
influxdb.write_points(data, precision, retention)

```

Write asynchronously (note that a retention policy cannot be specified for asynchronous writes):

``` ruby
require 'influxdb'

username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new database,
                                username: username,
                                password: password,
                                async: true

data = {
  values: { value: 0 },
  tags: { foo: 'bar', bar: 'baz' }
  timestamp: Time.now.to_i
}

influxdb.write_point(name, data)
```

Write data via UDP (note that a retention policy cannot be specified for UDP writes):

``` ruby
require 'influxdb'
host = '127.0.0.1'
port = 4444

influxdb = InfluxDB::Client.new udp: { host: host, port: port }

name = 'hitchhiker'

data = {
  values: { value: 666 },
  tags: { foo: 'bar', bar: 'baz' }
}

influxdb.write_point(name, data)
```

Querying:

``` ruby
username = 'foo'
password = 'bar'
database = 'site_development'

influxdb = InfluxDB::Client.new database,
                                username: username,
                                password: password

# without a block:
influxdb.query 'select * from time_series_1' # results are grouped by name, but also their tags

# result:
# [{"name"=>"time_series_1", "tags"=>{"region"=>"uk"}, "values"=>[{"time"=>"2015-07-09T09:03:31Z", "count"=>32, "value"=>0.9673}, {"time"=>"2015-07-09T09:03:49Z", "count"=>122, "value"=>0.4444}]},
# {"name"=>"time_series_1", "tags"=>{"region"=>"us"}, "values"=>[{"time"=>"2015-07-09T09:02:54Z", "count"=>55, "value"=>0.4343}]}]

# with a block:
influxdb.query 'select * from time_series_1' do |name, tags, points|
  puts "#{name} [ #{tags} ] => #{points}"
end

# result:
# time_series_1 [ {"region"=>"uk"} ] => [{"time"=>"2015-07-09T09:03:31Z", "count"=>32, "value"=>0.9673}, {"time"=>"2015-07-09T09:03:49Z", "count"=>122, "value"=>0.4444}]
# time_series_1 [ {"region"=>"us"} ] => [{"time"=>"2015-07-09T09:02:54Z", "count"=>55, "value"=>0.4343}]
```

If you would rather receive points with integer timestamp, it's possible to set `epoch` parameter:

``` ruby
# globally, on client initialization:
influxdb = InfluxDB::Client.new database, epoch: 's'

influxdb.query 'select * from time_series'
# result:
# [{"name"=>"time_series", "tags"=>{"region"=>"uk"}, "values"=>[{"time"=>1438411376, "count"=>32, "value"=>0.9673}]}]

# or for a specific query call:
influxdb.query 'select * from time_series', epoch: 'ms'
# result:
# [{"name"=>"time_series", "tags"=>{"region"=>"uk"}, "values"=>[{"time"=>1438411376000, "count"=>32, "value"=>0.9673}]}]
```

By default, InfluxDB::Client will denormalize points (received from InfluxDB as columns and rows), if you want to get _raw_ data add `denormalize: false` to initialization options or to query itself:

``` ruby
influxdb.query 'select * from time_series_1', denormalize: false

# result
[{"name"=>"time_series_1", "tags"=>{"region"=>"uk"}, "columns"=>["time", "count", "value"], "values"=>[["2015-07-09T09:03:31Z", 32, 0.9673], ["2015-07-09T09:03:49Z", 122, 0.4444]]},
 {"name"=>"time_series_1", "tags"=>{"region"=>"us"}, "columns"=>["time", "count", "value"], "values"=>[["2015-07-09T09:02:54Z", 55, 0.4343]]}]


influxdb.query 'select * from time_series_1', denormalize: false do |name, tags, points|
  puts "#{name} [ #{tags} ] => #{points}"
end

# result:
# time_series_1 [ {"region"=>"uk"} ] => {"columns"=>["time", "count", "value"], "values"=>[["2015-07-09T09:03:31Z", 32, 0.9673], ["2015-07-09T09:03:49Z", 122, 0.4444]]}
# time_series_1 [ {"region"=>"us"} ] => {"columns"=>["time", "count", "value"], "values"=>[["2015-07-09T09:02:54Z", 55, 0.4343]]}
```

By default, InfluxDB::Client will keep trying to connect to the database when it gets connection denied, if you want to retry a finite number of times
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
