require "influxdb"

puts __FILE__
puts "\tRepro code for https://github.com/influxdata/influxdb-ruby/issues/201"
puts

client = InfluxDB::Client.new \
  database:         "db_two",
  username:         "test_user",
  password:         "resu_tset",
  retry:            false,
  epoch:            "s",
  time_precision:   "s"

client.create_retention_policy("testpol", "db_two", "1h", 1)
