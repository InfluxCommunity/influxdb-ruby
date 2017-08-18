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
      end

      def write(payload, _precision = nil, _retention_policy = nil, _database = nil)
        with_socket { |sock| sock.send(payload, 0) }
      end

      private

      def with_socket
        unless socket
          self.socket = UDPSocket.new
          socket.connect(host, port)
        end

        yield socket
      end
    end
  end
end
