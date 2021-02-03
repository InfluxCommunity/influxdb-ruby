module InfluxDB
  module Query
    module Cluster # :nodoc:
      def create_cluster_admin(username, password)
        execute("CREATE USER \"#{username}\" WITH PASSWORD '#{password}' WITH ALL PRIVILEGES")
      end

      def list_cluster_admins
        list_users.select { |u| u["admin".freeze] }.map { |u| u["username".freeze] }
      end

      def revoke_cluster_admin_privileges(username)
        execute("REVOKE ALL PRIVILEGES FROM \"#{username}\"")
      end
    end
  end
end
