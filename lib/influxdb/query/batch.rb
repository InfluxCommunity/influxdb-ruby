require_relative 'builder'

module InfluxDB
  module Query # :nodoc: all
    module Batch
      def batched_query( # rubocop:disable Metrics/MethodLength
        queries: [],
        denormalize:  config.denormalize,
        chunk_size:   config.chunk_size,
        **opts
      )
        return [] if queries.empty?

        url = full_url("/query".freeze, query_params(queries.join(""), opts))
        series = fetch_batched_series(get(url, parse: true, json_streaming: !chunk_size.nil?))

        if block_given?
          series.each do |s|
            values = denormalize ? denormalize_batched_series(s) : raw_values(s)
            yield s['name'.freeze], s['tags'.freeze], values
          end
        else
          denormalize ? denormalized_batched_series_list(series) : series
        end
      end

      private

      def denormalized_batched_series_list(series_list)
        series_list.map do |series|
          denormalized_series_list(series)
        end
      end

      def fetch_batched_series(response)
        response.fetch('results'.freeze, []).map do |result|
          result.fetch('series'.freeze, [])
        end
      end
    end
  end
end
