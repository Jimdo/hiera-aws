require 'aws-sdk'

module Hiera
  module Backend
    module Aws
      class NoHandlerError < StandardError; end
      class MissingFactError < StandardError; end

      class ElastiCache
        def initialize
          @client = AWS::ElastiCache::Client.new
        end

        attr_reader :client

        def lookup(key, scope)
          if respond_to? key
            send(key, scope)
          else
            raise NoHandlerError, "no handler for '#{key}' found."
          end
        end

        def cache_nodes_by_cache_cluster_id(scope)
          fact = "cache_cluster_id"
          cache_cluster_id = scope[fact]
          raise MissingFactError, "#{fact} not found" unless cache_cluster_id

          options = { :cache_cluster_id => cache_cluster_id, :show_cache_node_info => true }
          nodes = @client.describe_cache_clusters(options)[:cache_clusters].first[:cache_nodes]
          nodes.map { |node| "#{node[:endpoint][:address]}:#{node[:endpoint][:port]}" }
        end
      end
    end
  end
end
