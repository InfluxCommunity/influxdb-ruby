module InfluxDB
  module Query
    module Database # :nodoc:
      def create_database(name)
        execute("CREATE DATABASE #{name}")
      end

      def delete_database(name)
        execute("DROP DATABASE #{name}")
      end

      def list_databases
        resp = execute("SHOW DATABASES", parse: true)
        values = resp["results"][0]["series"][0]["values"]
        values && !values.empty? ? values.flatten.map {|v| { "name" => v }} : []
      end
    end
  end
end
