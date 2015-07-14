module InfluxDB
  module Query
    module ShardSpace # :nodoc:
      # TODO: support 0.9.x
      #
      # def configure_database(database_name, options = {})
      #   url  = full_url("/cluster/database_configs/#{database_name}")
      #   data = JSON.generate(default_database_configuration.merge(options))

      #   post(url, data)
      # end

      # def list_shard_spaces
      #   get full_url("/cluster/shard_spaces")
      # end

      # def shard_space_info(database_name, shard_space_name)
      #   list_shard_spaces.find do |shard_space|
      #     shard_space["database"] == database_name &&
      #       shard_space["name"] == shard_space_name
      #   end
      # end

      # def create_shard_space(database_name, options = {})
      #   url  = full_url("/cluster/shard_spaces/#{database_name}")
      #   data = JSON.generate(default_shard_space_options.merge(options))

      #   post(url, data)
      # end

      # def delete_shard_space(database_name, shard_space_name)
      #   delete full_url("/cluster/shard_spaces/#{database_name}/#{shard_space_name}")
      # end

      # ## Get the shard space first, so the user doesn't have to specify the existing options
      # def update_shard_space(database_name, shard_space_name, options)
      #   shard_space_options = shard_space_info(database_name, shard_space_name)
      #   shard_space_options.delete("database")

      #   url  = full_url("/cluster/shard_spaces/#{database_name}/#{shard_space_name}")
      #   data = JSON.generate(shard_space_options.merge(options))

      #   post(url, data)
      # end

      # def default_shard_space_options
      #   {
      #     "name"              => "default",
      #     "regEx"             => "/.*/",
      #     "retentionPolicy"   => "inf",
      #     "shardDuration"     => "7d",
      #     "replicationFactor" => 1,
      #     "split"             => 1
      #   }
      # end

      # def default_database_configuration
      #   { spaces:  [default_shard_space_options] }
      # end
    end
  end
end
