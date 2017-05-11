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
          .fetch("values".freeze, [])
          .flatten
          .map { |v| { "name".freeze => v } }
      end

      def show_field_keys
        query("SHOW FIELD KEYS".freeze, precision: nil).each_with_object({}) do |collection, keys|
          name    = collection.fetch("name")
          values  = collection.fetch("values", [])

          keys[name] = values.each_with_object({}) do |row, types|
            types[row.fetch("fieldKey")] = [row.fetch("fieldType")]
          end
        end
      end
    end
  end
end
