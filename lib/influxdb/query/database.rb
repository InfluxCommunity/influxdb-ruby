module InfluxDB
  module Query
    module Database # :nodoc:
      def create_database(name = nil)
        execute("CREATE DATABASE #{name || config.database}")
      end

      def delete_database(name = nil)
        execute("DROP DATABASE #{name || config.database}")
      end

      def list_databases
        resp = execute("SHOW DATABASES".freeze, parse: true)
        fetch_series(resp)
          .fetch(0, {})
          .fetch('values', [])
          .flatten
          .map { |v| { 'name' => v } }
      end
    end
  end
end
