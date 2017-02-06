module InfluxDB
  module Query
    module Series # :nodoc:
      def delete_series(name)
        execute("DROP SERIES FROM #{name}", db: config.database)
      end

      def list_series
        resp = execute("SHOW SERIES".freeze, parse: true, db: config.database)
        resp = fetch_series(resp)
        raw_values(resp[0])
          .fetch('values'.freeze, [])
          .map { |val| val[0].split(',')[0] }
          .uniq
      end
    end
  end
end
