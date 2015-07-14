module InfluxDB
  module Query
    module RetentionPolicy # :nodoc:
      def list_retention_policies(database)
        resp = execute("SHOW RETENTION POLICIES \"#{database}\"", parse: true)
        data = fetch_series(resp).fetch(0)

        data['values'].map do |policy|
          entry = policy.each.with_index.inject({}) do |hash, (value, index)|
            hash.tap { |h| h[data['columns'][index]] = value }
          end
        end
      end

    end
  end
end
