module InfluxDB
  module Query # :nodoc: all
    # rubocop:disable Metrics/AbcSize
    module Core
      def ping
        get "/ping"
      end

      # rubocop:disable Metrics/MethodLength
      def query(query, opts = {})
        precision   = opts.fetch(:precision, config.time_precision)
        denormalize = opts.fetch(:denormalize, config.denormalize)

        url = full_url("/query", q: query, db: config.database, precision: precision)
        series = fetch_series(get(url, parse: true))

        if block_given?
          series.each do |s|
            yield s['name'], s['tags'], denormalize ? denormalize_series(s) : raw_values(s)
          end
        else
          denormalize ? list_series(series) : series
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
      def write_points(data, precision = nil)
        data = data.is_a?(Array) ? data : [data]
        payload = generate_payload(data)
        writer.write(payload, precision)
      end

      # Example:
      # write_point('cpu', tags: {region: 'us'}, values: {internal: 60})
      def write_point(series, data, precision = nil)
        data.merge!(series: series)
        write_points(data, precision)
      end

      def write(data, precision)
        precision ||= config.time_precision
        url = full_url("/write", db: config.database, precision: precision)
        post(url, data)
      end

      private

      def list_series(series)
        series.map do |s|
          {
            'name' => s['name'],
            'tags' => s['tags'],
            'values' => denormalize_series(s)
          }
        end
      end

      def fetch_series(response)
        response.fetch('results', [])
          .fetch(0, {})
          .fetch('series', [])
      end

      def generate_payload(data)
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      def execute(query, options = {})
        url = full_url("/query", q: query)
        get(url, options)
      end

      def denormalize_series(series)
        series["values"].map do |values|
          Hash[series["columns"].zip(values)]
        end
      end

      def raw_values(series)
        series.select { |k, _| %w(columns values).include?(k) }
      end

      def full_url(path, params = {})
        unless basic_auth?
          params[:u] = config.username
          params[:p] = config.password
        end

        query = params.map { |k, v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)].join }.join("&")

        URI::Generic.build(path: File.join(config.prefix, path), query: query).to_s
      end
    end
  end
end
