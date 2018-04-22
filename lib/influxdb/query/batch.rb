module InfluxDB
  module Query
    # Batch collects multiple queries and executes them together.
    #
    # You shouldn't use Batch directly, instead call Client.batch, which
    # constructs a new batch for you.
    class Batch
      attr_reader :client, :statements

      def initialize(client)
        @client     = client
        @statements = []

        yield self if block_given?
      end

      def add(query, params: nil)
        statements << client.builder.build(query.chomp(";"), params)
        statements.size - 1
      end

      def execute(
        denormalize:  config.denormalize,
        chunk_size:   config.chunk_size,
        **opts,
        &block
      )
        return [] if statements.empty?

        url = full_url "/query".freeze, query_params(statements.join(";"), opts)
        series = fetch_series get(url, parse: true, json_streaming: !chunk_size.nil?)

        if denormalize
          build_denormalized_result(series, &block)
        else
          build_result(series, &block)
        end
      end

      private

      def build_result(series)
        return series.values unless block_given?

        series.each do |id, statement_results|
          statement_results.each do |s|
            yield id, s["name".freeze], s["tags".freeze], raw_values(s)
          end

          # indicate empty result: yield useful amount of "nothing"
          yield id, nil, {}, [] if statement_results.empty?
        end
      end

      def build_denormalized_result(series)
        return series.map { |_, s| denormalized_series_list(s) } unless block_given?

        series.each do |id, statement_results|
          statement_results.each do |s|
            yield id, s["name".freeze], s["tags".freeze], denormalize_series(s)
          end

          # indicate empty result: yield useful amount of "nothing"
          yield id, nil, {}, [] if statement_results.empty?
        end
      end

      def fetch_series(response)
        response.fetch("results".freeze).each_with_object({}) do |result, list|
          sid = result["statement_id".freeze]
          list[sid] = result.fetch("series".freeze, [])
        end
      end

      # build simple method delegators
      %i[
        config
        full_url
        query_params
        get
        raw_values
        denormalize_series
        denormalized_series_list
      ].each do |method_name|
        define_method(method_name) do |*args|
          client.send method_name, *args
        end
      end
    end
  end
end
