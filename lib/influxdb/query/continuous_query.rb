module InfluxDB
  module Query
    module ContinuousQuery # :nodoc:
      # NOTE: Only cluster admin can call this
      def continuous_queries(database)
        get full_url("/db/#{database}/continuous_queries")
      end

      # @example
      #
      # db.create_continuous_query(
      #   "select mean(sys) as sys, mean(usr) as usr from cpu group by time(15m)",
      #   "cpu.15m",
      # )
      #
      # NOTE: Only cluster admin can call this
      def create_continuous_query(query, name)
        query("#{query} into #{name}")
      end

      # NOTE: Only cluster admin can call this
      def list_continuous_queries
        query("list continuous queries")
          .fetch("continuous queries", [])
          .map { |l| l["query"] }
      end

      # NOTE: Only cluster admin can call this
      def delete_continuous_query(id)
        query("drop continuous query #{id}")
      end
    end
  end
end
