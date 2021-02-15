# influxdb-ruby

[![Gem Version](https://badge.fury.io/rb/influxdb.svg)](https://badge.fury.io/rb/influxdb)
[![Build Status](https://github.com/influxdata/influxdb-ruby/workflows/Tests/badge.svg)](https://github.com/influxdata/influxdb-ruby/actions)

The official Ruby client library for [InfluxDB](https://influxdata.com/time-series-platform/influxdb/).
Maintained by [@toddboom](https://github.com/toddboom) and [@dmke](https://github.com/dmke).

#### Note: This library is for use with InfluxDB 1.x. For connecting to InfluxDB 2.x instances, please use the [influxdb-client-ruby](https://github.com/influxdata/influxdb-client-ruby) client.

## Contents

- [Platform support](#platform-support)
- [Ruby support](#ruby-support)
- [Installation](#installation)
- [Usage](#usage)
  - [Creating a client](#creating-a-client)
  - [Writing data](#writing-data)
  - [A Note About Time Precision](#a-note-about-time-precision)
  - [Querying](#querying)
- [Advanced Topics](#advanced-topics)
  - [Administrative tasks](#administrative-tasks)
  - [Continuous queries](#continuous-queries)
  - [Retention policies](#retention-policies)
  - [Reading data](#reading-data)
    - [De-normalization](#de--normalization)
    - [Streaming response](#streaming-response)
    - [Retry](#retry)
- [List of configuration options](#list-of-configuration-options)
- [Testing](#testing)
- [Contributing](#contributing)

## Platform support

> **Support for InfluxDB v0.8.x is now deprecated**. The final version of this
> library that will support the older InfluxDB interface is `v0.1.9`, which is
> available as a gem and tagged on this repository.
>
> If you're reading this message, then you should only expect support for
> InfluxDB v0.9.1 and higher.

## Ruby support

Since v0.7.0, this gem requires Ruby >= 2.3.0. MRI 2.2 *should* still work,
however we are unable to test this properly, since our toolchain (Bundler)
has dropped support for it. Support for MRI < 2.2 is still available in the
v0.3.x series, see [stable-03 branch](https://github.com/influxdata/influxdb-ruby/tree/stable-03)
for documentation.

## Installation

```
$ [sudo] gem install influxdb
```

Or add it to your `Gemfile`, and run `bundle install`.

## Usage

*All examples assume you have a `require "influxdb"` in your code.*

### Creating a client

Connecting to a single host:

``` ruby
influxdb = InfluxDB::Client.new  # default connects to localhost:8086

# or
influxdb = InfluxDB::Client.new host: "influxdb.domain.com"
```

Connecting to multiple hosts (with built-in load balancing and failover):

``` ruby
influxdb = InfluxDB::Client.new hosts: ["influxdb1.domain.com", "influxdb2.domain.com"]
```

#### Using a configuration URL

You can also provide a URL to connect to your server. This is particulary
useful for 12-factor apps, i.e. you can put the configuration in an environment
variable:

``` ruby
url = ENV["INFLUXDB_URL"] || "https://influxdb.example.com:8086/database_name?retry=3"
influxdb = InfluxDB::Client.new url: url
```

Please note, that the config options found in the URL have a lower precedence
than those explicitly given in the options hash. This means, that the following
sample will use an open-timeout of 10 seconds:

``` ruby
url = "https://influxdb.example.com:8086/database_name?open_timeout=3"
influxdb = InfluxDB::Client.new url: url, open_timeout: 10
```

#### Using a custom HTTP Proxy

By default, the `Net::HTTP` proxy behavior is used (see [Net::HTTP Proxy][proxy])
You can optionally set a proxy address and port via the `proxy_addr` and
`proxy_port` options:

``` ruby
influxdb = InfluxDB::Client.new database,
  host:       "influxdb.domain.com",
  proxy_addr: "your.proxy.addr",
  proxy_port: 8080
```

[proxy]: https://docs.ruby-lang.org/en/2.7.0/Net/HTTP.html#class-Net::HTTP-label-Proxies

### Writing data

Write some data:

``` ruby
username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new database, username: username, password: password

# Enumerator that emits a sine wave
Value = (0..360).to_a.map {|i| Math.send(:sin, i / 10.0) * 10 }.each

loop do
  data = {
    values: { value: Value.next },
    tags:   { wave: 'sine' } # tags are optional
  }

  influxdb.write_point(name, data)

  sleep 1
end
```

Write data with time precision (precision can be set in 2 ways):

``` ruby
username       = 'foo'
password       = 'bar'
database       = 'site_development'
name           = 'foobar'
time_precision = 's'

# either in the client initialization:
influxdb = InfluxDB::Client.new database,
  username: username,
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

> **Attention:** Please also read the
> [note about time precision](#a-note-about-time-precision) below.

Allowed values for `time_precision` are:

- `"ns"` or `nil` for nanosecond
- `"u"` for microsecond
- `"ms"` for millisecond
- `"s"` for second
- `"m"` for minute
- `"h"` for hour

Write data with a specific retention policy:

``` ruby
database  = 'site_development'
name      = 'foobar'
precision = 's'
retention = '1h.cpu'

influxdb = InfluxDB::Client.new database,
  username: "foo",
  password: "bar"

data = {
  values:    { value: 0 },
  tags:      { foo: 'bar', bar: 'baz' },
  timestamp: Time.now.to_i
}

influxdb.write_point(name, data, precision, retention)
```

Write data while choosing the database:

``` ruby
database  = 'site_development'
name      = 'foobar'
precision = 's'
retention = '1h.cpu'

influxdb = InfluxDB::Client.new {
  username: "foo",
  password: "bar"
}

data = {
  values:    { value: 0 },
  tags:      { foo: 'bar', bar: 'baz' },
  timestamp: Time.now.to_i
}

influxdb.write_point(name, data, precision, retention, database)
```

Write multiple points in a batch (performance boost):

``` ruby
data = [
  {
    series: 'cpu',
    tags:   { host: 'server_1', region: 'us' },
    values: { internal: 5, external: 0.453345 }
  },
  {
    series: 'gpu',
    values: { value: 0.9999 },
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
    tags:   { host: 'server_1', region: 'us' },
    values: { internal: 5, external: 0.453345 }
  },
  {
    series: 'gpu',
    values: { value: 0.9999 },
  }
]

precision = 'm'
retention = '1h.cpu'
influxdb.write_points(data, precision, retention)
```

Write asynchronously:

``` ruby
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new database,
  username: "foo",
  password: "bar",
  async:    true

data = {
  values:    { value: 0 },
  tags:      { foo: 'bar', bar: 'baz' },
  timestamp: Time.now.to_i
}

influxdb.write_point(name, data)
```

<a name="async-options"></a>
Using `async: true` is a shortcut for the following:

``` ruby
async_options = {
  # number of points to write to the server at once
  max_post_points:     1000,
  # queue capacity
  max_queue_size:      10_000,
  # number of threads
  num_worker_threads:  3,
  # max. time (in seconds) a thread sleeps before
  # checking if there are new jobs in the queue
  sleep_interval:      5,
  # whether client will block if queue is full
  block_on_full_queue: false,
  # Max time (in seconds) the main thread will wait for worker threads to stop
  # on shutdown. Defaults to 2x sleep_interval.
  shutdown_timeout: 10
}

influxdb = InfluxDB::Client.new database, async: async_options
```

<a name="udp-options"></a>
Write data via UDP (note that a retention policy cannot be specified for UDP writes):

``` ruby
influxdb = InfluxDB::Client.new udp: { host: "127.0.0.1", port: 4444 }

name = 'hitchhiker'

data = {
  values: { value: 666 },
  tags:   { foo: 'bar', bar: 'baz' }
}

influxdb.write_point(name, data)
```

Discard write errors:

``` ruby
influxdb = InfluxDB::Client.new(
  udp: { host: "127.0.0.1", port: 4444 },
  discard_write_errors: true
)

influxdb.write_point('hitchhiker', { values: { value: 666 } })
```

### A Note About Time Precision

The default precision in this gem is `"s"` (second), as Ruby's `Time#to_i`
operates on this resolution.

If you write data points with sub-second resolution, you _have_ to configure
your client instance with a more granular `time_precision` option **and** you
need to provide timestamp values which reflect this precision. **If you don't do
this, your points will be squashed!**

> A point is uniquely identified by the measurement name, tag set, and
> timestamp. If you submit a new point with the same measurement, tag set, and
> timestamp as an existing point, the field set becomes the union of the old
> field set and the new field set, where any ties go to the new field set. This
> is the intended behavior.

See [How does InfluxDB handle duplicate points?][docs-faq] for details.

For example, this is how to specify millisecond precision (which moves the
pitfall from the second- to the millisecond barrier):

```ruby
client = InfluxDB::Client.new(time_precision: "ms")
time = (Time.now.to_r * 1000).to_i
client.write_point("foobar", { values: { n: 42 }, timestamp: time })
```

For convenience, InfluxDB provides a few helper methods:

```ruby
# to get a timestamp with the precision configured in the client:
client.now

# to get a timestamp with the given precision:
InfluxDB.now(time_precision)

# to convert a Time into a timestamp with the given precision:
InfluxDB.convert_timestamp(Time.now, time_precision)
```

As with `client.write_point`, allowed values for `time_precision` are:

- `"ns"` or `nil` for nanosecond
- `"u"` for microsecond
- `"ms"` for millisecond
- `"s"` for second
- `"m"` for minute
- `"h"` for hour

[docs-faq]: http://docs.influxdata.com/influxdb/v1.7/troubleshooting/frequently-asked-questions/#how-does-influxdb-handle-duplicate-points

### Querying

``` ruby
database = 'site_development'
influxdb = InfluxDB::Client.new database,
  username: "foo",
  password: "bar"

# without a block:
influxdb.query 'select * from time_series_1 group by region'

# results are grouped by name, but also their tags:
#
# [
#   {
#     "name"=>"time_series_1",
#     "tags"=>{"region"=>"uk"},
#     "values"=>[
#       {"time"=>"2015-07-09T09:03:31Z", "count"=>32, "value"=>0.9673},
#       {"time"=>"2015-07-09T09:03:49Z", "count"=>122, "value"=>0.4444}
#     ]
#   },
#   {
#     "name"=>"time_series_1",
#     "tags"=>{"region"=>"us"},
#     "values"=>[
#       {"time"=>"2015-07-09T09:02:54Z", "count"=>55, "value"=>0.4343}
#     ]
#   }
# ]

# with a block:
influxdb.query 'select * from time_series_1 group by region' do |name, tags, points|
  printf "%s [ %p ]\n", name, tags
  points.each do |pt|
    printf "  -> %p\n", pt
  end
end

# result:
# time_series_1 [ {"region"=>"uk"} ]
#   -> {"time"=>"2015-07-09T09:03:31Z", "count"=>32, "value"=>0.9673}
#   -> {"time"=>"2015-07-09T09:03:49Z", "count"=>122, "value"=>0.4444}]
# time_series_1 [ {"region"=>"us"} ]
#   -> {"time"=>"2015-07-09T09:02:54Z", "count"=>55, "value"=>0.4343}
```

If you would rather receive points with integer timestamp, it's possible to set
`epoch` parameter:

``` ruby
# globally, on client initialization:
influxdb = InfluxDB::Client.new database, epoch: 's'

influxdb.query 'select * from time_series group by region'
# [
#   {
#     "name"=>"time_series",
#     "tags"=>{"region"=>"uk"},
#     "values"=>[
#       {"time"=>1438411376, "count"=>32, "value"=>0.9673}
#     ]
#   }
# ]

# or for a specific query call:
influxdb.query 'select * from time_series group by region', epoch: 'ms'
# [
#   {
#     "name"=>"time_series",
#     "tags"=>{"region"=>"uk"},
#     "values"=>[
#       {"time"=>1438411376000, "count"=>32, "value"=>0.9673}
#     ]
#   }
# ]
```

Working with parameterized query strings works as expected:

``` ruby
influxdb = InfluxDB::Client.new database

named_parameter_query = "select * from time_series_0 where time > %{min_time}"
influxdb.query named_parameter_query, params: { min_time: 0 }
# compiles to:
#   select * from time_series_0 where time > 0

positional_params_query = "select * from time_series_0 where f = %{1} and i < %{2}"
influxdb.query positional_params_query, params: ["foobar", 42]
# compiles to (note the automatic escaping):
#   select * from time_series_0 where f = 'foobar' and i < 42
```

## Advanced Topics

### Administrative tasks

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

### Continuous Queries

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

Additionally, you can specify the resample interval and the time range over
which the CQ runs:

``` ruby
influxdb.create_continuous_query(name, database, query, resample_every: "10m", resample_for: "65m")
```

Delete a continuous query from a database:

``` ruby
database = 'foo'
name = 'clicks_count'

influxdb.delete_continuous_query(name, database)
```

### Retention Policies

List retention policies of a database:

``` ruby
database = 'foo'

influxdb.list_retention_policies(database)
```

Create a retention policy for a database:

``` ruby
database    = 'foo'
name        = '1h.cpu'
duration    = '10m'
replication = 2

influxdb.create_retention_policy(name, database, duration, replication)
```

Delete a retention policy from a database:

``` ruby
database = 'foo'
name     = '1h.cpu'

influxdb.delete_retention_policy(name, database)
```

Alter a retention policy for a database:

``` ruby
database    = 'foo'
name        = '1h.cpu'
duration    = '10m'
replication = 2

influxdb.alter_retention_policy(name, database, duration, replication)
```

### Reading data

#### (De-) Normalization

By default, InfluxDB::Client will denormalize points (received from InfluxDB as
columns and rows). If you want to get *raw* data add `denormalize: false` to
the initialization options or to query itself:

``` ruby
influxdb.query 'select * from time_series_1 group by region', denormalize: false

# [
#   {
#     "name"=>"time_series_1",
#     "tags"=>{"region"=>"uk"},
#     "columns"=>["time", "count", "value"],
#     "values"=>[
#       ["2015-07-09T09:03:31Z", 32, 0.9673],
#       ["2015-07-09T09:03:49Z", 122, 0.4444]
#     ]
#   },
#   {
#     "name"=>"time_series_1",
#     "tags"=>{"region"=>"us"},
#     "columns"=>["time", "count", "value"],
#     "values"=>[
#       ["2015-07-09T09:02:54Z", 55, 0.4343]
#     ]
#   }
# ]


influxdb.query 'select * from time_series_1 group by region', denormalize: false do |name, tags, points|
  printf "%s [ %p ]\n", name, tags
  points.each do |key, values|
    printf "  %p -> %p\n", key, values
  end
end

# time_series_1 [ {"region"=>"uk"} ]
#   columns -> ["time", "count", "value"]
#   values -> [["2015-07-09T09:03:31Z", 32, 0.9673], ["2015-07-09T09:03:49Z", 122, 0.4444]]}
# time_series_1 [ {"region"=>"us"} ]
#   columns -> ["time", "count", "value"]
#   values -> [["2015-07-09T09:02:54Z", 55, 0.4343]]}
```

You can also pick the database to query from:

```
influxdb.query 'select * from time_series_1', database: 'database'
```

#### Streaming response

If you expect large quantities of data in a response, you may want to enable
JSON streaming by setting a `chunk_size`:

``` ruby
influxdb = InfluxDB::Client.new database,
  username:   username,
  password:   password,
  chunk_size: 10000
```

See the [official documentation][docs-chunking] for more details.


#### Retry

By default, InfluxDB::Client will keep trying (with exponential fall-off) to
connect to the database until it gets a connection. If you want to retry only
a finite number of times (or disable retries altogether), you can pass the
`:retry` option.

`:retry` can be either `true`, `false` or an `Integer` to retry infinite times,
disable retries or retry a finite number of times, respectively. Passing `0` is
equivalent to `false` and `-1` is equivalent to `true`.

```
$ irb -r influxdb
> influxdb = InfluxDB::Client.new 'database', retry: 8
=> #<InfluxDB::Client:0x00000002bb5ce0 ...>

> influxdb.query 'select * from serie limit 1'
E, [2016-08-31T23:55:18.287947 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.01s.
E, [2016-08-31T23:55:18.298455 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.02s.
E, [2016-08-31T23:55:18.319122 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.04s.
E, [2016-08-31T23:55:18.359785 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.08s.
E, [2016-08-31T23:55:18.440422 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.16s.
E, [2016-08-31T23:55:18.600936 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.32s.
E, [2016-08-31T23:55:18.921740 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 0.64s.
E, [2016-08-31T23:55:19.562428 #23476] WARN  -- InfluxDB: Failed to contact host localhost: #<Errno::ECONNREFUSED: Failed to open TCP connection to localhost:8086 (Connection refused - connect(2) for "localhost" port 8086)> - retrying in 1.28s.
InfluxDB::ConnectionError: Tried 8 times to reconnect but failed.
```

## List of configuration options

This index might be out of date. Please refer to `InfluxDB::DEFAULT_CONFIG_OPTIONS`,
found in `lib/influxdb/config.rb` for the source of truth.

| Category        | Option                  | Default value | Notes
|:----------------|:------------------------|:--------------|:-----
| HTTP connection | `:host` or `:hosts`     | "localhost"   | can be an array and can include port
|                 | `:port`                 | 8086          | fallback port, unless provided by `:host` option
|                 | `:prefix`               | ""            | URL path prefix (e.g. server is behind reverse proxy)
|                 | `:username`             | "root"        | user credentials
|                 | `:password`             | "root"        | user credentials
|                 | `:open_timeout`         | 5             | socket timeout
|                 | `:read_timeout`         | 300           | socket timeout
|                 | `:auth_method`          | "params"      | "params", "basic_auth" or "none"
| Retry           | `:retry`                | -1            | max. number of retry attempts (reading and writing)
|                 | `:initial_delay`        | 0.01          | initial wait time (doubles every retry attempt)
|                 | `:max_delay`            | 30            | max. wait time when retrying
| SSL/HTTPS       | `:use_ssl`              | false         | whether or not to use SSL (HTTPS)
|                 | `:verify_ssl`           | true          | verify vertificate when using SSL
|                 | `:ssl_ca_cert`          | false         | path to or name of CA cert
| Database        | `:database`             | *empty*       | name of database
|                 | `:time_precision`       | "s"           | time resolution for data send to server
|                 | `:epoch`                | false         | time resolution for server responses (false = server default)
| Writer          | `:async`                | false         | Async options hash, [details here](#async-options)
|                 | `:udp`                  | false         | UDP connection info, [details here](#udp-options)
|                 | `:discard_write_errors` | false         | suppress UDP socket errors
| Query           | `:chunk_size`           | *empty*       | [details here](#streaming-response)
|                 | `:denormalize`          | true          | format of result

## Testing

```
git clone git@github.com:influxdata/influxdb-ruby.git
cd influxdb-ruby
bundle
bundle exec rake
```

## Contributing

- Fork this repository on GitHub.
- Make your changes.
  - Add tests.
  - Add an entry in the `CHANGELOG.md` in the "unreleased" section on top.
- Run the tests: `bundle exec rake`.
- Send a pull request.
  - Please rebase against the master branch.
- If your changes look good, we'll merge them.
