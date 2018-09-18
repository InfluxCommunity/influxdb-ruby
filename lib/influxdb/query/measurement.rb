module InfluxDB
  module Query
    module Measurement # :nodoc:
      def list_measurements(database = config.database)
        data = execute("SHOW MEASUREMENTS", db: database, parse: true)
        return nil if data.nil? || data["results"][0]["series"].nil?

        data["results"][0]["series"][0]["values"].flatten
      end

      def delete_measurement(measurement_name, database = config.database)
        execute "DROP MEASUREMENT \"#{measurement_name}\"", db: database
        true
      end
    end
  end
end
