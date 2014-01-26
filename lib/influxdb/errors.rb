module InfluxDB
  class Error < StandardError
  end

  class AuthenticationError < Error
  end

  class ConnectionError < Error
  end

  class JSONParserError < Error
  end
end
