module InfluxDB
  module Query
    module ContinuousQuery # :nodoc:
      def list_continuous_queries(database)
        resp = execute("SHOW CONTINUOUS QUERIES", parse: true)
        fetch_series(resp)
          .select { |v| v['name'] == database }
          .fetch(0, {})
          .fetch('values', [])
          .map { |v| { 'name' => v.first, 'query' => v.last } }
      end

      def create_continuous_query(name, database, query, resample_every: nil, resample_for: nil)
        clause = ["CREATE CONTINUOUS QUERY", name, "ON", database]

        if resample_every || resample_for
          clause << "RESAMPLE".freeze
          clause << "EVERY #{resample_every}" if resample_every
          clause << "FOR #{resample_for}"     if resample_for
        end

        clause = clause.join(" ".freeze) << " BEGIN\n".freeze << query << "\nEND".freeze
        execute(clause)
      end

      def delete_continuous_query(name, database)
        execute("DROP CONTINUOUS QUERY #{name} ON #{database}")
      end
    end
  end
end
