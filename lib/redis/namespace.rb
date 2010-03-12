require 'redis'

class Redis
  class Namespace
    # The following table defines how input parameters and result
    # values should be modified for the namespace.
    #
    # Generated from http://code.google.com/p/redis/wiki/CommandReference
    # using the following jQuery:
    #
    # $('.vt li a').map(function(i,e){return $(e).text().toLowerCase()}).sort().toArray()
    COMMANDS = {
      "auth"             => [ :none,         :none    ],
      "bgrewriteaof"     => [ :none,         :none    ],
      "bgsave"           => [ :none,         :none    ],
      "blpop"            => [ :exclude_last, :none    ],
      "brpop"            => [ :exclude_last, :none    ],
      "dbsize"           => [ :none,         :none    ],
      "decr"             => [ :first,        :none    ],
      "decrby"           => [ :first,        :none    ],
      "del"              => [ :all,          :none    ],
      "exists"           => [ :first,        :none    ],
      "expire"           => [ :first,        :none    ],
      "flushall"         => [ :none,         :none    ],
      "flushdb"          => [ :none,         :none    ],
      "get"              => [ :first,        :none    ],
      "getset"           => [ :first,        :none    ],
      "incr"             => [ :first,        :none    ],
      "incrby"           => [ :first,        :none    ],
      "info"             => [ :none,         :none    ],
      "keys"             => [ :first,        :all     ],
      "lastsave"         => [ :none,         :none    ],
      "lindex"           => [ :first,        :none    ],
      "llen"             => [ :first,        :none    ],
      "lpop"             => [ :first,        :none    ],
      "lpush"            => [ :first,        :none    ],
      "lrange"           => [ :first,        :none    ],
      "lrem"             => [ :first,        :none    ],
      "lset"             => [ :first,        :none    ],
      "ltrim"            => [ :first,        :none    ],
      "mapped_mget"      => [ :all,          :all     ],
      "mget"             => [ :all,          :none    ],
      "monitor"          => [ :monitor,      :none    ],
      "move"             => [ :first,        :none    ],
      "mset"             => [ :alternate,    :none    ],
      "msetnx"           => [ :alternate,    :none    ],
      "quit"             => [ :none,         :none    ],
      "randomkey"        => [ :none,         :none    ],
      "rename"           => [ :all,          :none    ],
      "renamenx"         => [ :all,          :none    ],
      "rpop"             => [ :first,        :none    ],
      "rpoplpush"        => [ :all,          :none    ],
      "rpush"            => [ :first,        :none    ],
      "sadd"             => [ :first,        :none    ],
      "save"             => [ :none,         :none    ],
      "scard"            => [ :first,        :none    ],
      "sdiff"            => [ :all,          :none    ],
      "sdiffstore"       => [ :all,          :none    ],
      "select"           => [ :none,         :none    ],
      "set"              => [ :first,        :none    ],
      "setnx"            => [ :first,        :none    ],
      "shutdown"         => [ :none,         :none    ],
      "sinter"           => [ :all,          :none    ],
      "sinterstore"      => [ :all,          :none    ],
      "sismember"        => [ :first,        :none    ],
      "slaveof"          => [ :none,         :none    ],
      "smembers"         => [ :first,        :none    ],
      "smove"            => [ :exclude_last, :none    ],
      "sort"             => [ :sort,         :none    ],
      "spop"             => [ :first,        :none    ],
      "srandmember"      => [ :first,        :none    ],
      "srem"             => [ :first,        :none    ],
      "sunion"           => [ :all,          :none    ],
      "sunionstore"      => [ :all,          :none    ],
      "ttl"              => [ :first,        :none    ],
      "type"             => [ :first,        :none    ],
      "zadd"             => [ :first,        :none    ],
      "zcard"            => [ :first,        :none    ],
      "zincrby"          => [ :first,        :none    ],
      "zrange"           => [ :first,        :none    ],
      "zrangebyscore"    => [ :first,        :none    ],
      "zrem"             => [ :first,        :none    ],
      "zremrangebyscore" => [ :first,        :none    ],
      "zrevrange"        => [ :first,        :none    ],
      "zscore"           => [ :first,        :none    ],
      "[]"               => [ :first,        :none    ],
      "[]="              => [ :first,        :none    ]
    }


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

    def method_missing(command, *args, &block)
      (before, after) = COMMANDS[command.to_s] || COMMANDS[Redis::ALIASES[command.to_s]]

      # Add the namespace to any parameters that are keys.
      case before
      when :first
        args[0] = add_namespace(args[0]) if args[0]
      when :all
        args = add_namespace(args)
      when :exclude_first
        first = args.shift
        args = add_namespace(args)
        args.unshift(first) if first
      when :exclude_last
        last = args.pop
        args = add_namespace(args)
        args.push(last) if last
      when :alternate
        args = [ add_namespace(Hash[*args]) ]
      end

      # Dispatch the command to Redis and store the result.
      result = @redis.send(command, *args, &block)

      # Remove the namespace from results that are keys.
      result = rem_namespace(result) if after == :all

      result
    end

    private

    def add_namespace(key)
      return key unless key && @namespace

      case key
      when Array
        key.map {|k| add_namespace k}
      when Hash
        Hash[*key.map {|k, v| [ add_namespace(k), v ]}.flatten]
      else
        "#{@namespace}:#{key}"
      end
    end

    def rem_namespace(key)
      return key unless key && @namespace

      case key
      when Array
        key.map {|k| rem_namespace k}
      when Hash
        Hash[*key.map {|k, v| [ rem_namespace(k), v ]}.flatten]
      else
        key.to_s.gsub /^#{@namespace}:/, ""
      end
    end
  end
end
