require 'redis'

class Redis
  class Namespace
    # Generated from http://code.google.com/p/redis/wiki/CommandReference
    # using the following jQuery:
    #
    # $('.vt li a').map(function(i,e){return $(e).text().toLowerCase()}).sort().toArray()
    COMMANDS = [
      "auth",
      "bgrewriteaof",
      "bgsave",
      "blpop",
      "brpop",
      "dbsize",
      "decr",
      "decrby",
      "del",
      "exists",
      "expire",
      "flushall",
      "flushdb",
      "get",
      "getset",
      "incr",
      "incrby",
      "info",
      "keys",
      "lastsave",
      "lindex",
      "llen",
      "lpop",
      "lpush",
      "lrange",
      "lrem",
      "lset",
      "ltrim",
      "mget",
      "monitor",
      "move",
      "mset",
      "msetnx",
      "quit",
      "randomkey",
      "rename",
      "renamenx",
      "rpop",
      "rpoplpush",
      "rpush",
      "sadd",
      "save",
      "scard",
      "sdiff",
      "sdiffstore",
      "select",
      "set",
      "setnx",
      "shutdown",
      "sinter",
      "sinterstore",
      "sismember",
      "slaveof",
      "smembers",
      "smove",
      "sort",
      "spop",
      "srandmember",
      "srem",
      "sunion",
      "sunionstore",
      "ttl",
      "type",
      "zadd",
      "zcard",
      "zincrby",
      "zrange",
      "zrangebyscore",
      "zrem",
      "zremrangebyscore",
      "zrevrange",
      "zscore",
      "[]",
      "[]="
    ]

    attr_accessor :namespace

    def initialize(namespace, options = {})
      @namespace = namespace
      @redis = options[:redis]
    end

    # Ruby defines a now deprecated type method so we need to override it here
    # since it will never hit method_missing
    def type(key)
      method_missing(:type, key)
    end

    def del(*keys)
      keys = keys.map { |key| "#{@namespace}:#{key}"} if @namespace
      call_command([:del] + keys)
    end

    def mapped_mget(*keys)
      result = {}
      mget(*keys).each do |value|
        key = keys.shift
        result.merge!(key => value) unless value.nil?
      end
      result
    end

    def mget(*keys)
      keys = keys.map { |key| "#{@namespace}:#{key}"} if @namespace
      call_command([:mget] + keys)
    end

    def mset(keys)
      call_mset(:mset, keys)
    end

    def msetnx(keys)
      call_mset(:msetnx, keys)
    end

    def method_missing(command, *args, &block)
      if COMMANDS.include?(command.to_s) && args[0]
        args[0] = "#{@namespace}:#{args[0]}"
      end

      @redis.send(command, *args, &block)
    end


    private


    def call_mset(command, keys)
      if @namespace
        namespaced_keys = {}
        keys.each { |key, value| namespaced_keys["#{@namespace}:#{key}"] = value }
        keys = namespaced_keys
      end

      call_command([command] + [keys])
    end
  end
end
