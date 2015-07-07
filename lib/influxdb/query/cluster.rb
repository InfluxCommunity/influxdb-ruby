module InfluxDB
  module Query
    module Cluster # :nodoc:
      def create_cluster_admin(username, password)
        url = full_url("/cluster_admins")
        data = JSON.generate(name: username, password: password)
        post(url, data)
      end

      def update_cluster_admin(username, password)
        url = full_url("/cluster_admins/#{username}")
        data = JSON.generate(password: password)
        post(url, data)
      end

      def delete_cluster_admin(username)
        delete full_url("/cluster_admins/#{username}")
      end

      def list_cluster_admins
        get full_url("/cluster_admins")
      end

      def authenticate_cluster_admin
        get full_url('/cluster_admins/authenticate'), json: false
      end
    end
  end
end
