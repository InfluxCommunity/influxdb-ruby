require "influxdb"

#
# This is basically a test whether the examples in documented on
# http://docs.influxdata.com/influxdb/v0.13/sample_data/data_download/
# work with the Ruby client.
#

client = InfluxDB::Client.new \
  database: "NOAA_water_database"
  username: "test_user",
  password: "resu_tset",
  retry:    4

#
# See all five measurements
#

result      = Result.from_query "show measurements"
expected    = %w[ average_temperature h2o_feet h2o_pH h2o_quality h2o_temperature ]
actual      = result[0]["values"].map{|v| v["name"] }
unexpected  = actual - expected
raise "unexpected measurements: #{unexpected.join(", ")}" if unexpected.any?

#
# Count the number of non-null values of water_level in h2o_feet
#

result      = client.query "select count(water_level) from h2o_feet"
expected    = 15258
actual      = result[0]["values"]["count"]
raise "expected to find #{expected} points, got #{actual}" if expected != actual

#
# Select the first five observations in the measurement h2o_feet
#

result = client.query "select * from h2o_feet limit 5"
raise "expected 5 observations, got #{result.size}" if results.size != 5

expected = { "time"=>"2015-08-18T00:00:00Z", "level description" => "between 6 and 9 feet", "location"=>"coyote_creek", "water_level" => 8.12}
raise "unexpected first result, got #{result[0]}" if expected != result[0]

expected = { "time" => "2015-08-18T00:12:00Z", "level description" => "between 6 and 9 feet", "location" => "coyote_creek", "water_level" => 7.887}
raise "unexpected last result, got #{result[-1]}" if expected != result[-1]
