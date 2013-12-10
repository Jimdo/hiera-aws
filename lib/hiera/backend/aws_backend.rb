require "hiera/backend/aws/elasticache"

module Hiera
  module Backend
    class Aws_Backend
      def initialize
        begin
          require "aws-sdk"
        rescue LoadError
          require "rubygems"
          require "aws-sdk"
        end

        Hiera.debug("AWS backend initialized")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Backend.datasources(scope, order_override) do |elem|
          case elem
          when /aws\/elasticache\/(.+)/
            Hiera.debug("Looking up #{key} on elasticache cluster '#{$1}'")
            
            ec = Hiera::Aws::Elasticache.new

            case key
            when "cache_nodes"
              raw_answer = @elasticache.cache_cluster_nodes $1
            when "some_test_array"
              raw_answer = [ "/tmp/wurstbrot1", "/tmp/wurstbrot2", "/tmp/wurstbrot3" ]
            else
              raise "dont know how to lookup key #{key}"
            end
          end

          new_answer = Backend.parse_answer(raw_answer, scope)

          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer)
          else
            answer = new_answer
            break
          end

          answer
        end
      end
    end
  end
end
