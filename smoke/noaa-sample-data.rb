require "influxdb"

puts __FILE__
puts "\tThis is basically a test whether the examples in documented on"
puts "\thttp://docs.influxdata.com/influxdb/v0.13/sample_data/data_download/"
puts "\twork with the Ruby client."
puts

client = InfluxDB::Client.new \
  database: "NOAA_water_database",
  username: "test_user",
  password: "resu_tset",
  retry:    4

TestFailure         = Class.new StandardError
TestAllowedFailure  = Class.new StandardError

def test_case(name)
  print name
  yield
  puts " [ OK ]"

rescue TestAllowedFailure
  puts " [WARN]"
  puts $!.message

rescue TestFailure
  puts " [FAIL]"
  puts $!.message
  exit 1
end

test_case "See all five measurements?" do
  result      = client.query "show measurements"
  expected    = %w[ average_temperature h2o_feet h2o_pH h2o_quality h2o_temperature ]
  actual      = result[0]["values"].map{|v| v["name"] }
  unexpected  = actual - expected
  if unexpected.any?
    raise TestFailure, "unexpected measurements: #{unexpected.join(", ")}"
  end
end

test_case "Count the number of non-null values of water_level in h2o_feet" do
  result      = client.query "select count(water_level) from h2o_feet"
  expected    = 15258
  actual      = result[0]["values"][0]["count"]
  if expected != actual
    raise TestFailure, "expected to find #{expected} points, got #{actual}"
  end
end

test_case "Select the first five observations in the measurement h2o_feet" do
  result    = client.query("select * from h2o_feet limit 5").first["values"]
  expected  = 5
  actual    = result.size
  if expected != actual
    raise TestFailure, "expected #{expected} observations, got #{actual}"
  end

  expected = {
    "time"              => "2015-08-18T00:00:00Z",
    "level description" => "between 6 and 9 feet",
    "location"          => "coyote_creek",
    "water_level"       => 8.12
  }
  if expected != result[0]
    raise TestAllowedFailure, "unexpected first result, got #{result[0]}"
  end

  expected = {
    "time"              => "2015-08-18T00:12:00Z",
    "level description" => "between 6 and 9 feet",
    "location"          => "coyote_creek",
    "water_level"       => 7.887
  }
  if expected != result[-1]
    raise TestAllowedFailure, "unexpected last result, got #{result[-1]}"
  end
end
