require "spec_helper"

describe "issue201 repro code", smoke: true do
  def gen_data(t_ref, age)
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
      timestamp: t_ref.to_i - age,
    }
  end

  let(:database)  { "issue201" }
  let(:now)       { Time.now }
  let(:from_time) { now.to_i - 200 }
  let(:to_time)   { now.to_i + 50 }

  let(:client) do
    InfluxDB::Client.new \
      database:       database,
      username:       "root",
      password:       "toor",
      retry:          false,
      epoch:          "s",
      time_precision: "s"
  end

  before do
    WebMock.allow_net_connect!
    client.create_database database
  end

  after do
    client.delete_database database
    WebMock.disable_net_connect!
  end

  context "with RP and data" do
    before do
      client.create_retention_policy("testpol", database, "1h", 1)
      data = 100.times.map{|i| gen_data(now, 100-i) }
      client.write_points(data, "s", "testpol")
    end

    it "doesn't fail with normal heredoc" do
      expect {
        q = <<-SQL
          SELECT SUM(call_count) as call_count, SUM(call_time) as total_call_time, MAX(max_call_time) as max_call_time, MEAN(percentile_95th) as percentile_95th
            FROM #{database}.testpol.dbmetrics_1
            WHERE
              time >= #{from_time}s
              AND time < #{to_time}s
              AND (app = '6')
              AND ((model_name = 'Request' AND operation = 'save') OR (model_name = 'Request' AND operation = 'find'))
            GROUP BY model_name,operation,scope
        SQL

        p q
        client.query(q)
      }.not_to raise_error
    end

    it "doesn't fail with squiggly heredoc" do
      expect {
        q = <<~SQL
          SELECT SUM(call_count) as call_count, SUM(call_time) as total_call_time, MAX(max_call_time) as max_call_time, MEAN(percentile_95th) as percentile_95th
            FROM #{database}.testpol.dbmetrics_1
            WHERE
              time >= #{from_time}s
              AND time < #{to_time}s
              AND (app = '6')
              AND ((model_name = 'Request' AND operation = 'save') OR (model_name = 'Request' AND operation = 'find'))
            GROUP BY model_name,operation,scope
        SQL

        p q
        client.query(q)
      }.not_to raise_error
    end
  end
end
