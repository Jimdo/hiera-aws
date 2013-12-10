module Hiera
  module Backend
    module Aws
      class ElastiCache
        def lookup(key, params)
        end

#            case key
#            when "cache_nodes"
#              raw_answer = @elasticache.cache_cluster_nodes $1
#            when "some_test_array"
#              raw_answer = [ "/tmp/wurstbrot1", "/tmp/wurstbrot2", "/tmp/wurstbrot3" ]
#            else
#              raise "dont know how to lookup key #{key}"
#            end

        
# class ElastiCache
#   def initialize
#     @client = AWS::ElastiCache::Client.new
#   end
# 
#   def cache_cluster(cache_cluster_id)
#     options = { :cache_cluster_id => cache_cluster_id, :show_cache_node_info => true }
#     @client.describe_cache_clusters(options)[:cache_clusters].first
#   end
# 
#   def cache_cluster_nodes(cache_cluster_id)
#     cluster = cache_cluster(cache_cluster_id)
#     nodes = cluster[:cache_nodes]
#     ["a", "b"] + nodes.map { |node| "#{node[:endpoint][:address]}:#{node[:endpoint][:port]}" }
#   end
# end

      end
    end
  end
end
