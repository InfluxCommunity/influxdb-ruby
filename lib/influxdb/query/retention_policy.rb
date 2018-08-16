module InfluxDB
  module Query
    module RetentionPolicy # :nodoc:
      def create_retention_policy(name,
                                  database,
                                  duration,
                                  replication,
                                  default = false,
                                  shard_duration: nil)
        execute(
          "CREATE RETENTION POLICY \"#{name}\" ON \"#{database}\" " \
          "DURATION #{duration} REPLICATION #{replication}" \
          "#{shard_duration ? " SHARD DURATION #{shard_duration}" : ''}" \
          "#{default ? ' DEFAULT' : ''}"
        )
      end

      def list_retention_policies(database)
        resp = execute("SHOW RETENTION POLICIES ON \"#{database}\"", parse: true)
        data = fetch_series(resp).fetch(0, {})

        data.fetch("values".freeze, []).map do |policy|
          policy.each.with_index.inject({}) do |hash, (value, index)|
            hash.tap { |h| h[data['columns'.freeze][index]] = value }
          end
        end
      end

      def delete_retention_policy(name, database)
        execute("DROP RETENTION POLICY \"#{name}\" ON \"#{database}\"")
      end

      def alter_retention_policy(name,
                                 database,
                                 duration,
                                 replication,
                                 default = false,
                                 shard_duration: nil)
        execute(
          "ALTER RETENTION POLICY \"#{name}\" ON \"#{database}\" " \
          "DURATION #{duration} REPLICATION #{replication}" \
          "#{shard_duration ? " SHARD DURATION #{shard_duration}" : ''}" \
          "#{default ? ' DEFAULT' : ''}"
        )
      end
    end
  end
end
