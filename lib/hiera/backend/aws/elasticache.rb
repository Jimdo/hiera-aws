require 'aws-sdk'

class Hiera
  module Backend
    module Aws
      class NoHandlerError < StandardError; end
      class MissingFactError < StandardError; end

      class ElastiCache
        def initialize
          @scope = {}
        end

        def client
          region = @scope.fetch("location", "eu-west-1")
          AWS::ElastiCache::Client.new :region => region
        end

        def lookup(key, scope)
          if respond_to? key
            @scope = scope
            send(key)
          else
            raise NoHandlerError, "no handler for '#{key}' found."
          end
        end

        def cache_nodes_by_cache_cluster_id
          cache_cluster_id = @scope["cache_cluster_id"]
          raise MissingFactError, "cache_cluster_id not found" unless cache_cluster_id
          options = { :cache_cluster_id => cache_cluster_id, :show_cache_node_info => true }
          nodes = client.describe_cache_clusters(options)[:cache_clusters].first[:cache_nodes]
          nodes.map { |node| "#{node[:endpoint][:address]}:#{node[:endpoint][:port]}" }
        end
      end
    end
  end
end
