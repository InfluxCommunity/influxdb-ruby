module InfluxDB
  class Error < StandardError
  end

  class AuthenticationError < Error
  end

  class ConnectionError < Error
  end
end
