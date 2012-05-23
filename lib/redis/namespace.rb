require 'redis'

class Redis
  class Namespace
    # The following table defines how input parameters and result
    # values should be modified for the namespace.
    #
    # COMMANDS is a hash. Each key is the name of a command and each
    # value is a two element array.
    #
    # The first element in the value array describes how to modify the
    # arguments passed. It can be one of:
    #
    #   nil
    #     Do nothing.
    #   :first
    #     Add the namespace to the first argument passed, e.g.
    #       GET key => GET namespace:key
    #   :all
    #     Add the namespace to all arguments passed, e.g.
    #       MGET key1 key2 => MGET namespace:key1 namespace:key2
    #   :exclude_first
    #     Add the namespace to all arguments but the first, e.g.
    #   :exclude_last
    #     Add the namespace to all arguments but the last, e.g.
    #       BLPOP key1 key2 timeout =>
    #       BLPOP namespace:key1 namespace:key2 timeout
    #   :exclude_options
    #     Add the namespace to all arguments, except the last argument,
    #     if the last argument is a hash of options.
    #       ZUNIONSTORE key1 2 key2 key3 WEIGHTS 2 1 =>
    #       ZUNIONSTORE namespace:key1 2 namespace:key2 namespace:key3 WEIGHTS 2 1
    #   :alternate
    #     Add the namespace to every other argument, e.g.
    #       MSET key1 value1 key2 value2 =>
    #       MSET namespace:key1 value1 namespace:key2 value2
    #
    # The second element in the value array describes how to modify
    # the return value of the Redis call. It can be one of:
    #
    #   nil
    #     Do nothing.
    #   :all
    #     Add the namespace to all elements returned, e.g.
    #       key1 key2 => namespace:key1 namespace:key2
    COMMANDS = {
      "auth"             => [],
      "bgrewriteaof"     => [],
      "bgsave"           => [],
      "blpop"            => [ :exclude_last, :first ],
      "brpop"            => [ :exclude_last ],
      "dbsize"           => [],
      "debug"            => [ :exclude_first ],
      "decr"             => [ :first ],
      "decrby"           => [ :first ],
      "del"              => [ :all   ],
      "exists"           => [ :first ],
      "expire"           => [ :first ],
      "expireat"         => [ :first ],
      "flushall"         => [],
      "flushdb"          => [],
      "get"              => [ :first ],
      "getset"           => [ :first ],
      "hset"             => [ :first ],
      "hsetnx"           => [ :first ],
      "hget"             => [ :first ],
      "hincrby"          => [ :first ],
      "hmget"            => [ :first ],
      "hmset"            => [ :first ],
      "hdel"             => [ :first ],
      "hexists"          => [ :first ],
      "hlen"             => [ :first ],
      "hkeys"            => [ :first ],
      "hvals"            => [ :first ],
      "hgetall"          => [ :first ],
      "incr"             => [ :first ],
      "incrby"           => [ :first ],
      "info"             => [],
      "keys"             => [ :first, :all ],
      "lastsave"         => [],
      "lindex"           => [ :first ],
      "llen"             => [ :first ],
      "lpop"             => [ :first ],
      "lpush"            => [ :first ],
      "lrange"           => [ :first ],
      "lrem"             => [ :first ],
      "lset"             => [ :first ],
      "ltrim"            => [ :first ],
      "mapped_hmset"     => [ :first ],
      "mapped_hmget"     => [ :first ],
      "mapped_mget"      => [ :all, :all ],
      "mget"             => [ :all ],
      "monitor"          => [ :monitor ],
      "move"             => [ :first ],
      "mset"             => [ :alternate ],
      "msetnx"           => [ :alternate ],
      "psubscribe"       => [ :all ],
      "publish"          => [ :first ],
      "punsubscribe"     => [ :all ],
      "quit"             => [],
      "randomkey"        => [],
      "rename"           => [ :all ],
      "renamenx"         => [ :all ],
      "rpop"             => [ :first ],
      "rpoplpush"        => [ :all ],
      "rpush"            => [ :first ],
      "sadd"             => [ :first ],
      "save"             => [],
      "scard"            => [ :first ],
      "sdiff"            => [ :all ],
      "sdiffstore"       => [ :all ],
      "select"           => [],
      "set"              => [ :first ],
      "setex"            => [ :first ],
      "setnx"            => [ :first ],
      "shutdown"         => [],
      "sinter"           => [ :all ],
      "sinterstore"      => [ :all ],
      "sismember"        => [ :first ],
      "slaveof"          => [],
      "smembers"         => [ :first ],
      "smove"            => [ :exclude_last ],
      "sort"             => [ :sort  ],
      "spop"             => [ :first ],
      "srandmember"      => [ :first ],
      "srem"             => [ :first ],
      "subscribe"        => [ :all ],
      "sunion"           => [ :all ],
      "sunionstore"      => [ :all ],
      "ttl"              => [ :first ],
      "type"             => [ :first ],
      "unsubscribe"      => [ :all ],
      "zadd"             => [ :first ],
      "zcard"            => [ :first ],
      "zcount"           => [ :first ],
      "zincrby"          => [ :first ],
      "zinterstore"      => [ :exclude_options ],
      "zrange"           => [ :first ],
      "zrangebyscore"    => [ :first ],
      "zrank"            => [ :first ],
      "zrem"             => [ :first ],
      "zremrangebyrank"  => [ :first ],
      "zremrangebyscore" => [ :first ],
      "zrevrange"        => [ :first ],
      "zrevrangebyscore" => [ :first ],
      "zrevrank"         => [ :first ],
      "zscore"           => [ :first ],
      "zunionstore"      => [ :exclude_options ],
      "[]"               => [ :first ],
      "[]="              => [ :first ]
    }

    # support previous versions of redis gem
    ALIASES = case
              when defined? Redis::Client::ALIASES  then Redis::Client::ALIASES
              when defined? Redis::ALIASES          then Redis::ALIASES
              else {}
              end

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

    alias_method :self_respond_to?, :respond_to?

    def respond_to?(command)
      if self_respond_to?(command)
        true
      else
        @redis.respond_to?(command)
      end
    end

    def keys(query = nil)
      query.nil? ? super("*") : super
    end

    def method_missing(command, *args, &block)
      handling = COMMANDS[command.to_s] ||
        COMMANDS[ALIASES[command.to_s]]

      # redis-namespace does not know how to handle this command.
      # Passing it to @redis as is.
      if handling.nil?
        return @redis.send(command, *args, &block)
      end

      (before, after) = handling

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
      when :exclude_options
        if args.last.is_a?(Hash)
          last = args.pop
          args = add_namespace(args)
          args.push(last)
        else
          args = add_namespace(args)
        end
      when :alternate
        args.each_with_index { |a, i| args[i] = add_namespace(a) if i.even? }
      when :sort
        args[0] = add_namespace(args[0]) if args[0]
        [:by, :get, :store].each do |key|
          args[1][key] = add_namespace(args[1][key]) if args[1][key]
        end if args[1].is_a?(Hash)
      end

      # Dispatch the command to Redis and store the result.
      result = @redis.send(command, *args, &block)

      # Remove the namespace from results that are keys.
      case after
      when :all
        result = rem_namespace(result)
      when :first
        result[0] = rem_namespace(result[0]) if result
      end

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
