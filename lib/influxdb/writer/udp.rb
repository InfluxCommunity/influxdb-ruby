module InfluxDB
  module Writer
    # Writes data to InfluxDB through UDP
    class UDP
      attr_accessor :socket
      attr_reader :host, :port
      def initialize(client, config)
        @client = client
        config = config.is_a?(Hash) ? config : {}
        @host = config.fetch(:host, 'localhost')
        @port = config.fetch(:port, 4444)
        self.socket = UDPSocket.new
        socket.connect(host, port)
      end

      def write(payload, _precision = nil)
        socket.send(payload, 0)
      end
    end
  end
end
