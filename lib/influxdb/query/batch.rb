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
        return series unless block_given?

        series.each_with_index do |s,i|
          if s[0]
            yield i, s[0]["name".freeze], s[0]["tags".freeze], raw_values(s[0])
          else
            yield i, nil, nil, []
          end
        end
      end

      def build_denormalized_result(series)
        return series.map { |s| denormalized_series_list(s) } unless block_given?

        series.each_with_index do |s,i|
          if s[0]
            yield i, s[0]["name".freeze], s[0]["tags".freeze], denormalize_series(s[0])
          else
            yield i, nil, nil, []
          end
        end
      end

      def fetch_series(response)
        response.fetch("results".freeze, []).map do |result|
          result.fetch("series".freeze, [])
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
