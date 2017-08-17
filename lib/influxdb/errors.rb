require "net/http"
require "zlib"

module InfluxDB # :nodoc:
  Error               = Class.new StandardError
  AuthenticationError = Class.new Error
  ConnectionError     = Class.new Error
  SeriesNotFound      = Class.new Error
  JSONParserError     = Class.new Error
  QueryError          = Class.new Error

  # When executing queries via HTTP, some errors can more or less safely
  # be ignored and we can retry the query again. This following
  # exception classes shall be deemed as "safe".
  #
  # Taken from: https://github.com/lostisland/faraday/blob/master/lib/faraday/adapter/net_http.rb
  RECOVERABLE_EXCEPTIONS = [
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
    (OpenSSL::SSL::SSLError if defined?(OpenSSL)),
  ].compact.freeze

  # Exception classes which hint to a larger problem on the server side,
  # like insuffient resources. If we encouter on of the following, wo
  # _don't_ retry a query but escalate it upwards.
  NON_RECOVERABLE_EXCEPTIONS = [
    EOFError,
    Zlib::Error,
  ].freeze

  NON_RECOVERABLE_MESSAGE = "The server has sent incomplete data" \
    " (insufficient resources are a possible cause).".freeze
end
