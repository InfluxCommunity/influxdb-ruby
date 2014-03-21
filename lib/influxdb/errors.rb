module InfluxDB
  class Error < Exception
  end

  class AuthenticationError < Error
  end

  class ConnectionError < Error
  end

  class JSONParserError < Error
  end
end
