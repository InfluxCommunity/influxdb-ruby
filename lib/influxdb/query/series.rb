module InfluxDB
  module Query
    module Series # :nodoc:
      def delete_series(name)
        execute_db("DROP SERIES FROM #{name}")
      end

      def list_series
        resp = execute_db("SHOW SERIES".freeze, parse: true)
        resp = fetch_series(resp)
        raw_values(resp[0])
          .fetch('values', [])
          .map { |val| val[0].split(',')[0] }
          .uniq
      end
    end
  end
end
