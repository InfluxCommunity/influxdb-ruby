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

      def create_continuous_query(name, database, query, options = {})
        clause = ["CREATE CONTINUOUS QUERY", name, "ON", database]

        if options[:resample_every] || options[:resample_for]
          clause << "RESAMPLE"
          clause << "EVERY #{options[:resample_every]}" if options[:resample_every]
          clause << "FOR #{options[:resample_for]}"     if options[:resample_for]
        end

        clause = clause.join(" ") << " BEGIN\n" << query << "\nEND"
        execute(clause)
      end

      def delete_continuous_query(name, database)
        execute("DROP CONTINUOUS QUERY #{name} ON #{database}")
      end
    end
  end
end
