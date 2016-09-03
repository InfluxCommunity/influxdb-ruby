require "influxdb"

puts __FILE__
puts "\tThis file contains some sanity checks."
puts

client = InfluxDB::Client.new \
  username: "test_user",
  password: "resu_tset",
  retry:    4

version = client.version

if version
  puts "Got version: #{version}"
else
  raise "version is empty"
end
