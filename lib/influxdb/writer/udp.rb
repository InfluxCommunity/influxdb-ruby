module InfluxDB
  module Writer
    # Writes data to InfluxDB through UDP
    class UDP
      attr_accessor :socket
      attr_reader :host, :port

      def initialize(client, host: "localhost".freeze, port: 4444)
        @client = client
        @host = host
        @port = port
        self.socket = UDPSocket.new
        socket.connect(host, port)
      end

      def write(payload, _precision = nil, _retention_policy = nil, _database = nil)
        socket.send(payload, 0)
      end
    end
  end
end
