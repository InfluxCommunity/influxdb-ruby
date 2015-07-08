module InfluxDB
  module Query # :nodoc: all
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    module Core

      def ping
        get "/ping"
      end

      def query(query, opts = {})
        precision = opts.fetch(:precision, config.time_precision)
        url = full_url("/query", q: query, db: config.database, precision: precision)
        resp = get(url, parse: true)
        series = resp["results"][0]["series"]
        return nil unless series && !series.empty?

        if block_given?
          series.each { |s| yield s['name'], s['tags'], denormalize_series(s) }
        else
          series.map do |s|
            {
              'name' => s['name'],
              'tags' => s['tags'],
              'values' => denormalize_series(s)
            }
          end
        end
      end

      # Example:
      #
      # Single point:
      # write_points(series: 'cpu', tags: {region: 'us'}, values: {internal: 66})
      #
      # Multiple points:
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
      #
      # NOTE: +tags+ are optional
      # NOTE: +timestamp+ is optional, if you decide to provide it, remember to
      # keep it compatible with requested time_precision
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

      def generate_payload(data)
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      def execute(query, options={})
        url = full_url("/query", q: query)
        get(url, options)
      end

      def denormalize_series(series)
        series["values"].map do |values|
          Hash[series["columns"].zip(values)]
        end
      end

      def full_url(path, params = {})
        unless basic_auth?
          params[:u] = config.username
          params[:p] = config.password
        end

        query = params.map { |k, v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)].join }.join("&")

        URI::Generic.build(path: path, query: query).to_s
      end
    end
  end
end
