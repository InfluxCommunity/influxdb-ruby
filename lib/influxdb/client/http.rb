require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'

module InfluxDB
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  module HTTP # :nodoc:
    def get(url, options = {})
      connect_with_retry do |http|
        response = do_request http, Net::HTTP::Get.new(url)
        if response.is_a? Net::HTTPSuccess
          return JSON.parse(response.body) if options.fetch(:json, true)
          response
        elsif response.is_a? Net::HTTPUnauthorized
          fail InfluxDB::AuthenticationError, response.body
        else
          resolve_error(response.body)
        end
      end
    end

    def post(url, data)
      headers = { "Content-Type" => "application/json" }
      connect_with_retry do |http|
        response = do_request http, Net::HTTP::Post.new(url, headers), data
        if response.is_a? Net::HTTPSuccess
          return response
        elsif response.is_a? Net::HTTPUnauthorized
          fail InfluxDB::AuthenticationError, response.body
        else
          resolve_error(response.body)
        end
      end
    end

    def delete(url, data = nil)
      headers = { "Content-Type" => "application/json" }
      connect_with_retry do |http|
        response = do_request http, Net::HTTP::Delete.new(url, headers), data
        if response.is_a? Net::HTTPSuccess
          return response
        elsif response.is_a? Net::HTTPUnauthorized
          fail InfluxDB::AuthenticationError, response.body
        else
          resolve_error(response.body)
        end
      end
    end

    private

    def connect_with_retry(&block)
      hosts = config.hosts.dup
      delay = config.initial_delay
      retry_count = 0

      begin
        hosts.push(host = hosts.shift)
        http = Net::HTTP.new(host, config.port)
        http.open_timeout = config.open_timeout
        http.read_timeout = config.read_timeout
        http.use_ssl = config.use_ssl
        block.call(http)

      rescue Timeout::Error, *InfluxDB::NET_HTTP_EXCEPTIONS => e
        retry_count += 1
        if (config.retry == -1 || retry_count <= config.retry) && !stopped?
          log :error, "Failed to contact host #{host}: #{e.inspect} - retrying in #{delay}s."
          sleep delay
          delay = [config.max_delay, delay * 2].min
          retry
        else
          raise e, "Tried #{retry_count - 1} times to reconnect but failed."
        end
      ensure
        http.finish if http.started?
      end
    end

    def do_request(http, req, data = nil)
      req.basic_auth config.username, config.password if basic_auth?
      http.request(req, data)
    end

    def basic_auth?
      config.auth_method == 'basic_auth'
    end

    def resolve_error(response)
      if response =~ /Couldn\'t find series/
        fail InfluxDB::SeriesNotFound, response
      else
        fail InfluxDB::Error, response
      end
    end
  end
end
