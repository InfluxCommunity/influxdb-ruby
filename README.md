influxdb-ruby
=============

![InfluxDB Build Status](https://travis-ci.org/influxdb/influxdb-ruby.png)

Ruby client library for [InfluxDB](http://influxdb.org/).

Install
-------

```
$ [sudo] gem install influxdb
```

Or add it to your `Gemfile`, etc.

Usage
-----

Create a database:

``` ruby
require 'influxdb'

hostname = 'localhost'
port     = 8086
username = 'root'
password = 'root'
database = 'site_development'

influxdb = InfluxDB::Client.new(username, port, username, password)

influxdb.create_database(database)
```

Create a user for a database:

``` ruby
require 'influxdb'

hostname = 'localhost'
port     = 8086
username = 'root'
password = 'root'
database = 'site_development'

influxdb = InfluxDB::Client.new(hostname, port, username, password)

new_username = 'foo'
new_password = 'bar'
influxdb.create_database_user(database, new_username, new_password)
```

Write some data:

``` ruby
require 'influxdb'

hostname = 'localhost'
port     = 8086
username = 'foo'
password = 'bar'
database = 'site_development'
name     = 'foobar'

influxdb = InfluxDB::Client.new(hostname, port, username, password, database)

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

List databases:

``` ruby
require 'influxdb'

hostname = 'localhost'
port     = 8086
username = 'root'
password = 'root'

influxdb = InfluxDB::Client.new(hostname, 8086, username, password)

influxdb.get_database_list
```

Delete a database:

``` ruby
require 'influxdb'

hostname = 'localhost'
port     = 8086
username = 'root'
password = 'root'
database = 'site_development'

influxdb = InfluxDB::Client.new(username, port, username, password)

influxdb.delete_database(database)
```


Testing
-------

```
git clone git@github.com:influxdb/influxdb-ruby.git
cd influxdb-ruby
bundle
rake 
```
