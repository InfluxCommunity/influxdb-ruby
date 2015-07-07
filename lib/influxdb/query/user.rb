module InfluxDB
  module Query
    module User # :nodoc:
      def create_database_user(database, username, password, options = {})
        url = full_url("/db/#{database}/users")
        data = JSON.generate({ name: username, password: password }.merge(options))
        post(url, data)
      end

      def update_database_user(database, username, options = {})
        url = full_url("/db/#{database}/users/#{username}")
        data = JSON.generate(options)
        post(url, data)
      end

      def delete_database_user(database, username)
        delete full_url("/db/#{database}/users/#{username}")
      end

      def list_database_users(database)
        get full_url("/db/#{database}/users")
      end

      def database_user_info(database, username)
        get full_url("/db/#{database}/users/#{username}")
      end

      def alter_database_privilege(database, username, admin = true)
        update_database_user(database, username, admin: admin)
      end

      def authenticate_database_user(database)
        get full_url("/db/#{database}/authenticate"), json: false
      end
    end
  end
end
