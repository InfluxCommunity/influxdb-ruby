module InfluxDB
  module Query # :nodoc: all
    # rubocop:disable Metrics/AbcSize
    module Core
      def ping
        get "/ping".freeze
      end

      def version
        resp = get "/ping".freeze
        resp.header['x-influxdb-version']
      end

      # rubocop:disable Metrics/MethodLength
      def query(query, opts = {})
        denormalize = opts.fetch(:denormalize, config.denormalize)
        json_streaming = !opts.fetch(:chunk_size, config.chunk_size).nil?

        params = query_params(query, opts)
        url = full_url("/query".freeze, params)
        series = fetch_series(get(url, parse: true, json_streaming: json_streaming))

        if block_given?
          series.each do |s|
            values = denormalize ? denormalize_series(s) : raw_values(s)
            yield s['name'.freeze], s['tags'.freeze], values
          end
        else
          denormalize ? denormalized_series_list(series) : series
        end
      end
      # rubocop:enable Metrics/MethodLength

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
      def write_points(data, precision = nil, retention_policy = nil)
        data = data.is_a?(Array) ? data : [data]
        payload = generate_payload(data)
        writer.write(payload, precision, retention_policy)
      end

      # Example:
      # write_point('cpu', tags: {region: 'us'}, values: {internal: 60})
      def write_point(series, data, precision = nil, retention_policy = nil)
        write_points(data.merge(series: series), precision, retention_policy)
      end

      def write(data, precision, retention_policy = nil)
        precision ||= config.time_precision
        params      = { db: config.database, precision: precision }
        params[:rp] = retention_policy if retention_policy
        url = full_url("/write", params)
        post(url, data)
      end

      private

      def query_params(query, opts)
        precision   = opts.fetch(:precision, config.time_precision)
        epoch       = opts.fetch(:epoch, config.epoch)
        chunk_size  = opts.fetch(:chunk_size, config.chunk_size)

        params = { q: query, db: config.database, precision: precision }
        params[:epoch] = epoch if epoch

        if chunk_size
          params[:chunked] = 'true'
          params[:chunk_size] = chunk_size
        end

        params
      end

      def denormalized_series_list(series)
        series.map do |s|
          {
            "name"   => s["name".freeze],
            "tags"   => s["tags".freeze],
            "values" => denormalize_series(s)
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

      def execute(query, options = {})
        url = full_url("/query", q: query)
        get(url, options)
      end

      def denormalize_series(series)
        Array(series["values".freeze]).map do |values|
          Hash[series["columns".freeze].zip(values)]
        end
      end

      def raw_values(series)
        series.select { |k, _| %w(columns values).include?(k) }
      end

      def full_url(path, params = {})
        if config.auth_method == "params".freeze
          params[:u] = config.username
          params[:p] = config.password
        end

        query = params.map do |k, v|
          [CGI.escape(k.to_s), "=".freeze, CGI.escape(v.to_s)].join
        end.join("&".freeze)

        URI::Generic.build(path: File.join(config.prefix, path), query: query).to_s
      end
    end
  end
end
