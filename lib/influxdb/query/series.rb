module InfluxDB
  module Query
    module Series # :nodoc:
      def delete_series(name, where: nil, db: config.database)
        if where
          execute("DROP SERIES FROM \"#{name}\" WHERE #{where}", db: db)
        else
          execute("DROP SERIES FROM \"#{name}\"", db: db)
        end
      end

      def list_series
        resp = execute("SHOW SERIES".freeze, parse: true, db: config.database)
        resp = fetch_series(resp)
        return [] if resp.empty?

        raw_values(resp[0])
          .fetch('values'.freeze, [])
          .map { |val| val[0].split(',')[0] }
          .uniq
      end
    end
  end
end
