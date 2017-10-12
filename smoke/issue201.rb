require "influxdb"

puts __FILE__
puts "\tRepro code for https://github.com/influxdata/influxdb-ruby/issues/201"
puts

client = InfluxDB::Client.new \
  database:         "db_two",
  username:         "root",
  password:         "toor",
  retry:            false,
  epoch:            "s",
  time_precision:   "s"

puts "-- create retention policy"
client.create_retention_policy("testpol", "db_two", "1h", 1)

def gen_data(age)
  {
    series: "dbmetrics_1",
    values: {
      call_count:       age + rand(10),
      call_time:        age + rand,
      max_call_time:    rand(80..120),
      percentile_95th:  42.5 + rand,
    },
    tags: {
      app:          rand > 0.2 ? "6" : (rand(10)+1).to_s,
      model_name:   "Request",
      operation:    rand > 0.5 ? "save" : "find",
      scope:        "myscope",
    },
    timestamp: Time.now.to_i - age,
  }
end

puts "-- writing 100 points"
data = 100.times.map{|i| p gen_data(100-i) }
client.write_points(data, "s", "testpol")

from_time = Time.now.to_i - 200
to_time = Time.now.to_i + 50

query = <<~SQL
SELECT SUM(call_count) as call_count, SUM(call_time) as total_call_time, MAX(max_call_time) as max_call_time, MEAN(percentile_95th) as percentile_95th
  FROM db_two.testpol.dbmetrics_1
  WHERE
    time >= #{from_time}s
    AND time < #{to_time}s
    AND (app = '6')
    AND ((model_name = 'Request' AND operation = 'save') OR (model_name = 'Request' AND operation = 'find'))
  GROUP BY model_name,operation,scope
SQL

puts "-- query data"
client.query(query) do |name, tags, points|
  printf "%s [ %p ]\n", name, tags
  points.each do |pt|
    printf "  -> %p\n", pt
  end
end

exit 0
