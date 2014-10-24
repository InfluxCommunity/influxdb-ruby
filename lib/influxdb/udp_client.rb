require "json"

module InfluxDB
  class UDPClient
    attr_accessor :socket
    def initialize(host, port)
      self.socket = UDPSocket.new
      self.socket.connect(host, port)
    end

    def send(payload)
      socket.send(JSON.generate(payload), 0)
    rescue
    end
  end
end
