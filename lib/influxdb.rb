require "influxdb/version"

module InfluxDB
  class Client
    def initialize(host, port, username, password, database)
      @host = host
      @port = port
      @username = username
      @password = password
      @database = database
    end
  end
end
