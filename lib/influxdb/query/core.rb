require_relative 'batch'
require_relative 'builder'

module InfluxDB
  module Query # :nodoc: all
    module Core
      def builder
        @builder ||= Builder.new
      end

      def ping
        url = URI::Generic.build(path: File.join(config.prefix, '/ping')).to_s
        get url
      end

      def version
        ping.header['x-influxdb-version']
      end

      def query( # rubocop:disable Metrics/MethodLength
        query,
        params:       nil,
        denormalize:  config.denormalize,
        chunk_size:   config.chunk_size,
        **opts
      )
        query = builder.build(query, params)

        url = full_url("/query".freeze, query_params(query, opts))
        series = fetch_series(get(url, parse: true, json_streaming: !chunk_size.nil?))

        if block_given?
          series.each do |s|
            values = denormalize ? denormalize_series(s) : raw_values(s)
            yield s['name'.freeze], s['tags'.freeze], values
          end
        else
          denormalize ? denormalized_series_list(series) : series
        end
      end

      def batch(&block)
        Batch.new self, &block
      end

      # Example:
      # write_points([
      #   {
      #     series: 'cpu',
      #     tags: { host: 'server_nl', regios: 'us' },
      #     values: {internal: 5, external: 6},
      #     timestamp: 1422568543702900257
      #   },
      #   {
      #     series: 'gpu',
      #     values: {value: 0.9999},
      #   }
      # ])
      def write_points(data, precision = nil, retention_policy = nil, database = nil)
        data = data.is_a?(Array) ? data : [data]
        payload = generate_payload(data)
        writer.write(payload, precision, retention_policy, database)
      rescue StandardError => e
        raise e unless config.discard_write_errors

        log :error, "Cannot write data: #{e.inspect}"
      end

      # Example:
      # write_point('cpu', tags: {region: 'us'}, values: {internal: 60})
      def write_point(series, data, precision = nil, retention_policy = nil, database = nil)
        write_points(data.merge(series: series), precision, retention_policy, database)
      end

      def write(data, precision, retention_policy = nil, database = nil)
        params = {
          db:        database || config.database,
          precision: precision || config.time_precision,
        }

        params[:rp] = retention_policy if retention_policy
        url = full_url("/write", params)
        post(url, data)
      end

      private

      def query_params(
        query,
        precision:  config.time_precision,
        epoch:      config.epoch,
        chunk_size: config.chunk_size,
        database:   config.database
      )
        params = { q: query, db: database }
        params[:precision] = precision if precision
        params[:epoch]     = epoch     if epoch

        if chunk_size
          params[:chunked] = 'true'.freeze
          params[:chunk_size] = chunk_size
        end

        params
      end

      def denormalized_series_list(series)
        series.map do |s|
          {
            "name".freeze   => s["name".freeze],
            "tags".freeze   => s["tags".freeze],
            "values".freeze => denormalize_series(s),
          }
        end
      end

      def fetch_series(response)
        response.fetch('results'.freeze, []).flat_map do |result|
          result.fetch('series'.freeze, [])
        end
      end

      def generate_payload(data)
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n".freeze)
      end

      def execute(query, db: nil, **options)
        params = { q: query }
        params[:db] = db if db
        url = full_url("/query".freeze, params)
        get(url, options)
      end

      def denormalize_series(series)
        Array(series["values".freeze]).map do |values|
          Hash[series["columns".freeze].zip(values)]
        end
      end

      def raw_values(series)
        series.select { |k, _| %w[columns values].include?(k) }
      end

      def full_url(path, params = {})
        if config.auth_method == "params".freeze
          params[:u] = config.username
          params[:p] = config.password
        end

        URI::Generic.build(
          path:  File.join(config.prefix, path),
          query: cgi_escape_params(params)
        ).to_s
      end

      def cgi_escape_params(params)
        params.map do |k, v|
          [CGI.escape(k.to_s), "=".freeze, CGI.escape(v.to_s)].join
        end.join("&".freeze)
      end
    end
  end
end
