module InfluxDB
  module Query
    module User # :nodoc:
      # create_database_user('testdb', 'user', 'pass') - grants all privileges by default
      # create_database_user('testdb', 'user', 'pass', permissions: :read) - use [:read|:write|:all]
      def create_database_user(database, username, password, options = {})
        permissions = options.fetch(:permissions, :all)
        execute(
          "CREATE user #{username} WITH PASSWORD '#{password}'; "\
          "GRANT #{permissions.to_s.upcase} ON #{database} TO #{username}"
        )
      end

      def update_user_password(username, password)
        execute("SET PASSWORD FOR #{username} = '#{password}'")
      end

      # permission => [:all]
      def grant_user_admin_privileges(username)
        execute("GRANT ALL PRIVILEGES TO #{username}")
      end

      # permission => [:read|:write|:all]
      def grant_user_privileges(username, database, permission)
        execute("GRANT #{permission.to_s.upcase} ON #{database} TO #{username}")
      end

      def list_user_grants(username)
        execute("SHOW GRANTS FOR #{username}")
      end

      # permission => [:read|:write|:all]
      def revoke_user_privileges(username, database, permission)
        execute("REVOKE #{permission.to_s.upcase} ON #{database} FROM #{username}")
      end

      def delete_user(username)
        execute("DROP USER #{username}")
      end

      # => [{"username"=>"usr", "admin"=>true}, {"username"=>"justauser", "admin"=>false}]
      def list_users
        resp = execute("SHOW USERS".freeze, parse: true)
        fetch_series(resp)
          .fetch(0, {})
          .fetch('values'.freeze, [])
          .map { |v| { 'username' => v.first, 'admin' => v.last } }
      end
    end
  end
end
