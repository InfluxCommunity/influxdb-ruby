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
      data = %Q{{"name": "#{name}"}}
      response = http.request(Net::HTTP::Post.new(url), data)
    end

    def delete_database(name)
      http = Net::HTTP.new(@host, @port)
      url = "/db/#{name}?u=#{@username}&p=#{@password}"
      response = http.request(Net::HTTP::Delete.new(url))
    end
  end
end
