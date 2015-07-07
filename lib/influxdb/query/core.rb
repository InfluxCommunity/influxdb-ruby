module InfluxDB
  module Query # :nodoc: all
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    module Core
      def query(query, opts = {})
        time_precision = opts.fetch(:time_precision, config.time_precision)
        denormalize = opts.fetch(:denormalize, config.denormalize)
        url = full_url("/db/#{config.database}/series", q: query, time_precision: time_precision)
        series = get(url)

        if block_given?
          series.each { |s| yield s['name'], denormalize ? denormalize_series(s) : s }
        else
          return series unless denormalize

          series.each_with_object({}) do |s, col|
            name                  = s['name']
            denormalized_series   = denormalize_series(s)
            col[name]             = denormalized_series
            col
          end
        end
      end

      def ping
        get "/ping"
      end

      private

      def denormalize_series(series)
        columns = series['columns']

        h = Hash.new(-1)
        columns = columns.map do |v|
          h[v] += 1
          h[v] > 0 ? "#{v}~#{h[v]}" : v
        end

        series['points'].map do |point|
          decoded_point = point.map do |value|
            InfluxDB::PointValue.new(value).load
          end
          Hash[columns.zip(decoded_point)]
        end
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
