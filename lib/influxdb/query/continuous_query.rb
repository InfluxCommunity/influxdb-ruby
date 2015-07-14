module InfluxDB
  module Query
    module ContinuousQuery # :nodoc:
      def continuous_queries(database)
        resp = execute("SHOW CONTINUOUS QUERIES", parse: true)
        fetch_series(resp).select { |v| v['name'] == database }
          .fetch(0, {})
          .fetch('values', [])
          .map { |v| { 'name' => v.first, 'query' => v.last } }
      end
      # # @example
      # #
      # # db.create_continuous_query(
      # #   "select mean(sys) as sys, mean(usr) as usr from cpu group by time(15m)",
      # #   "cpu.15m",
      # # )
      # #
      # # NOTE: Only cluster admin can call this
      # def create_continuous_query(query, name)
      #   query("#{query} into #{name}")
      # end

      # # NOTE: Only cluster admin can call this
      # def list_continuous_queries
      #   query("list continuous queries")
      #     .fetch("continuous queries", [])
      #     .map { |l| l["query"] }
      # end

      # # NOTE: Only cluster admin can call this
      # def delete_continuous_query(id)
      #   query("drop continuous query #{id}")
      # end
    end
  end
end
