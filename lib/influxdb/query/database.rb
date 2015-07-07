module InfluxDB
  module Query
    module Database # :nodoc:
      # allow options, e.g. influxdb.create_database('foo', replicationFactor: 3)
      def create_database(name, options = {})
        url = full_url("/cluster/database_configs/#{name}")
        data = JSON.generate(options)
        post(url, data)
      end

      def delete_database(name)
        delete full_url("/db/#{name}")
      end

      def list_databases
        get full_url("/db")
      end
    end
  end
end
