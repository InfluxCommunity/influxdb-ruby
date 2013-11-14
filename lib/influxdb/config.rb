require 'json'

module InfluxDB
  class Config
    attr_accessor :path, :config

    # +:path+:: path to the config file
    # +:config+:: hash representing InfluxDB configuration
    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      @path   = opts[:path] || '/opt/influxdb/shared/config.json'
      @config = opts[:config] || default_config
    end

    def render
      return JSON.pretty_generate(@config)
    end

    def valid?(path=@path)
      begin
        JSON.parse(File.read(path))
        return true
      rescue JSON::ParserError
        return false
      end
    end

    private

    def default_config
      return {
        'AdminHttpPort' => 8083,
        'AdminAssetsDir' => '/opt/influxdb/current/admin',
        'ApiHttpPort' => 8086,
        'RaftServerPort' => 8090,
        'SeedServers' => [],
        'DataDir' => '/opt/influxdb/shared/data/db',
        'RaftDir' => '/opt/influxdb/shared/data/raft'
      }
    end

  end
end

