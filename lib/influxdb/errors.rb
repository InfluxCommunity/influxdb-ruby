require "net/http"
require "zlib"

module InfluxDB # :nodoc:
  class Error < StandardError
  end

  class AuthenticationError < Error
  end

  class ConnectionError < Error
  end

  class SeriesNotFound < Error
  end

  class JSONParserError < Error
  end

  class QueryError < Error
  end

  # Taken from: https://github.com/lostisland/faraday/blob/master/lib/faraday/adapter/net_http.rb
  NET_HTTP_EXCEPTIONS = [
    EOFError,
    Errno::ECONNABORTED,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::EINVAL,
    Errno::ENETUNREACH,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    SocketError,
    Zlib::GzipFile::Error
  ]

  NET_HTTP_EXCEPTIONS << OpenSSL::SSL::SSLError if defined?(OpenSSL)
end
