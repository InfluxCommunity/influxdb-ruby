require "net/http"

module InfluxDB
  class Client
    def initialize(host, port, username, password, database)
      @host = host
      @port = port
      @username = username
      @password = password
      @database = database
    end

    def create_database(name)
      http = Net::HTTP.new(@host, @port)
      url = "/db?u=#{@username}&p=#{@password}"
      data = JSON.generate({:name => name})
      response = http.request(Net::HTTP::Post.new(url), data)
    end

    def delete_database(name)
      http = Net::HTTP.new(@host, @port)
      url = "/db/#{name}?u=#{@username}&p=#{@password}"
      response = http.request(Net::HTTP::Delete.new(url))
    end

    def write_point(name, data)
      http = Net::HTTP.new(@host, @port)
      url = "/db/#{@database}/series?u=#{@username}&p=#{@password}"
      payload = {:name => name, :points => [], :columns => []}

      point = []
      data.each_pair do |k,v|
        payload[:columns].push k.to_s
        point.push v
      end

      payload[:points].push point
      data = JSON.generate(payload)
      response = http.request(Net::HTTP::Post.new(url), data)
    end
  end
end
