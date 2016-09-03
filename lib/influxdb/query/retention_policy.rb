module InfluxDB
  module Query
    module RetentionPolicy # :nodoc:
      def create_retention_policy(name, database, duration, replication, default = false)
        execute(
          "CREATE RETENTION POLICY \"#{name}\" ON #{database} " \
          "DURATION #{duration} REPLICATION #{replication}#{default ? ' DEFAULT' : ''}"
        )
      end

      def list_retention_policies(database)
        resp = execute("SHOW RETENTION POLICIES ON \"#{database}\"", parse: true)
        data = fetch_series(resp).fetch(0)

        data['values'.freeze].map do |policy|
          policy.each.with_index.inject({}) do |hash, (value, index)|
            hash.tap { |h| h[data['columns'.freeze][index]] = value }
          end
        end
      end

      def delete_retention_policy(name, database)
        execute("DROP RETENTION POLICY \"#{name}\" ON #{database}")
      end

      def alter_retention_policy(name, database, duration, replication, default = false)
        execute(
          "ALTER RETENTION POLICY \"#{name}\" ON #{database} " \
          "DURATION #{duration} REPLICATION #{replication}#{default ? ' DEFAULT' : ''}"
        )
      end
    end
  end
end
