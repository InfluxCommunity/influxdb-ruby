require "influxdb"

options = {
  username: "test_user",
  password: "resu_tset",
  retry:    4,
}


client = InfluxDB::Client.new options
version = client.version

if version
  puts "Got version: #{version}"
  exit 0
else
  raise "version is empty"
end
