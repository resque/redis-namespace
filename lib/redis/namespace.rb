require 'redis'
require 'redis/namespace/version'

class Redis
  # Redis::Namespace wraps a {Redis} (or another Redis::Namespace, or a
  # ConnectionPool of either) client object and transparently prefixes every
  # key-like argument passed through it with a namespace, and strips that
  # same prefix from any key-like values in the response.
  #
  # This lets multiple independent applications, or independent subsystems
  # of the same application, share a single Redis keyspace without their
  # keys colliding.
  #
  # @example Basic usage
  #   redis = Redis.new
  #   ns = Redis::Namespace.new(:ns, redis: redis)
  #   ns.set('foo', 'bar')      # => runs `SET ns:foo bar` on redis
  #   ns.get('foo')             # => "bar"
  #   redis.get('foo')          # => nil
  #   redis.get('ns:foo')       # => "bar"
  #
  # @example Dynamic (per-call) namespaces via Proc
  #   ns = Redis::Namespace.new(Proc.new { Tenant.current_tenant }, redis: redis)
  #
  # Only commands listed in {COMMANDS} are known to Redis::Namespace and can
  # be namespaced; see the "Blind Passthrough" and "Administrative Commands"
  # sections of the README for how unknown and administrative commands are
  # handled.
  class Namespace
    # The following tables define how input parameters and result
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
    #   :sort
    #     Add namespace to first argument if it is non-nil
    #     Add namespace to second arg's :by and :store if second arg is a Hash
    #     Add namespace to each element in second arg's :get if second arg is
    #       a Hash; forces second arg's :get to be an Array if present.
    #   :eval_style
    #     Add namespace to each element in keys argument (via options hash or multi-args)
    #   :scan_style
    #     Add namespace to :match option, or supplies "#{namespace}:*" if not present.
    #
    # The second element in the value array describes how to modify
    # the return value of the Redis call. It can be one of:
    #
    #   nil
    #     Do nothing.
    #   :all
    #     Add the namespace to all elements returned, e.g.
    #       key1 key2 => namespace:key1 namespace:key2
    NAMESPACED_COMMANDS = {
      "append"           => [:first],
      "bitcount"         => [:first],
      "bitfield"         => [:first],
      "bitop"            => [:exclude_first],
      "bitpos"           => [:first],
      "blpop"            => %i[exclude_last first],
      "brpop"            => %i[exclude_last first],
      "brpoplpush"       => [:exclude_last],
      "bzpopmin"         => [:first],
      "bzpopmax"         => [:first],
      "debug"            => [:exclude_first],
      "decr"             => [:first],
      "decrby"           => [:first],
      "del"              => [:all],
      "dump"             => [:first],
      "exists"           => [:all],
      "exists?"          => [:all],
      "expire"           => [:first],
      "expireat"         => [:first],
      "expiretime"       => [:first],
      "eval"             => [:eval_style],
      "evalsha"          => [:eval_style],
      "get"              => [:first],
      "getex"            => [:first],
      "getbit"           => [:first],
      "getrange"         => [:first],
      "getset"           => [:first],
      "hset"             => [:first],
      "hsetnx"           => [:first],
      "hget"             => [:first],
      "hincrby"          => [:first],
      "hincrbyfloat"     => [:first],
      "hmget"            => [:first],
      "hmset"            => [:first],
      "hdel"             => [:first],
      "hexists"          => [:first],
      "hlen"             => [:first],
      "hkeys"            => [:first],
      "hscan"            => [:first],
      "hscan_each"       => [:first],
      "hvals"            => [:first],
      "hgetall"          => [:first],
      "incr"             => [:first],
      "incrby"           => [:first],
      "incrbyfloat"      => [:first],
      "keys"             => %i[first all],
      "lindex"           => [:first],
      "linsert"          => [:first],
      "llen"             => [:first],
      "lpop"             => [:first],
      "lpos"             => [:first],
      "lpush"            => [:first],
      "lpushx"           => [:first],
      "lrange"           => [:first],
      "lrem"             => [:first],
      "lset"             => [:first],
      "ltrim"            => [:first],
      "mapped_hmset"     => [:first],
      "mapped_hmget"     => [:first],
      "mapped_mget"      => %i[all all],
      "mapped_mset"      => [:all],
      "mapped_msetnx"    => [:all],
      "mget"             => [:all],
      "monitor"          => [:monitor],
      "move"             => [:first],
      "mset"             => [:alternate],
      "msetnx"           => [:alternate],
      "object"           => [:exclude_first],
      "persist"          => [:first],
      "pexpire"          => [:first],
      "pexpireat"        => [:first],
      "pexpiretime"      => [:first],
      "pfadd"            => [:first],
      "pfcount"          => [:all],
      "pfmerge"          => [:all],
      "psetex"           => [:first],
      "psubscribe"       => [:all],
      "pttl"             => [:first],
      "publish"          => [:first],
      "punsubscribe"     => [:all],
      "rename"           => [:all],
      "renamenx"         => [:all],
      "restore"          => [:first],
      "rpop"             => [:first],
      "rpoplpush"        => [:all],
      "rpush"            => [:first],
      "rpushx"           => [:first],
      "sadd"             => [:first],
      "sadd?"            => [:first],
      "scard"            => [:first],
      "scan"             => %i[scan_style second],
      "scan_each"        => %i[scan_style all],
      "sdiff"            => [:all],
      "sdiffstore"       => [:all],
      "set"              => [:first],
      "setbit"           => [:first],
      "setex"            => [:first],
      "setnx"            => [:first],
      "setrange"         => [:first],
      "sinter"           => [:all],
      "sinterstore"      => [:all],
      "sismember"        => [:first],
      "smembers"         => [:first],
      "smismember"       => [:first],
      "smove"            => [:exclude_last],
      "sort"             => [:sort],
      "spop"             => [:first],
      "srandmember"      => [:first],
      "srem"             => [:first],
      "srem?"            => [:first],
      "sscan"            => [:first],
      "sscan_each"       => [:first],
      "strlen"           => [:first],
      "subscribe"        => [:all],
      "sunion"           => [:all],
      "sunionstore"      => [:all],
      "ttl"              => [:first],
      "type"             => [:first],
      "unlink"           => [:all],
      "unsubscribe"      => [:all],
      "zadd"             => [:first],
      "zcard"            => [:first],
      "zcount"           => [:first],
      "zincrby"          => [:first],
      "zinterstore"      => [:exclude_options],
      "zpopmin"          => [:first],
      "zpopmax"          => [:first],
      "zrange"           => [:first],
      "zrangebyscore"    => [:first],
      "zrangebylex"      => [:first],
      "zrank"            => [:first],
      "zrem"             => [:first],
      "zremrangebyrank"  => [:first],
      "zremrangebyscore" => [:first],
      "zremrangebylex"   => [:first],
      "zrevrange"        => [:first],
      "zrevrangebyscore" => [:first],
      "zrevrangebylex"   => [:first],
      "zrevrank"         => [:first],
      "zscan"            => [:first],
      "zscan_each"       => [:first],
      "zscore"           => [:first],
      "zunionstore"      => [:exclude_options]
    }.freeze
    # Commands that manage or participate in a Redis transaction (+MULTI+ /
    # +EXEC+ / +DISCARD+ / +WATCH+ / +UNWATCH+). See {#multi} and {#pipelined}.
    TRANSACTION_COMMANDS = {
      "discard" => [],
      "exec"    => [],
      "multi"   => [],
      "unwatch" => [:all],
      "watch"   => [:all]
    }.freeze
    # Connection/utility commands that never need namespacing.
    HELPER_COMMANDS = {
      "auth"        => [],
      "disconnect!" => [],
      "close"       => [],
      "echo"        => [],
      "ping"        => [],
      "time"        => []
    }.freeze
    # Commands whose effects cannot be scoped to a single namespace (e.g.
    # +FLUSHALL+, which truncates every database on the server). These are
    # deprecated for passthrough on Redis::Namespace instances; call them on
    # the underlying {#redis} connection directly instead. See the
    # "Administrative Commands" section of the README.
    ADMINISTRATIVE_COMMANDS = {
      "bgrewriteaof" => [],
      "bgsave"       => [],
      "config"       => [],
      "dbsize"       => [],
      "flushall"     => [],
      "flushdb"      => [],
      "info"         => [],
      "lastsave"     => [],
      "quit"         => [],
      "randomkey"    => [],
      "save"         => [],
      "script"       => [],
      "select"       => [],
      "shutdown"     => [],
      "slaveof"      => []
    }.freeze

    # Commands whose direct passthrough is deprecated; see {ADMINISTRATIVE_COMMANDS}.
    # When {#deprecations?} is true these commands raise +NoMethodError+
    # instead of passing through to {#redis}.
    DEPRECATED_COMMANDS = [
      ADMINISTRATIVE_COMMANDS
    ].compact.reduce(:merge)

    # The full set of commands Redis::Namespace knows how to handle, merged
    # from {NAMESPACED_COMMANDS}, {TRANSACTION_COMMANDS}, {HELPER_COMMANDS},
    # and {ADMINISTRATIVE_COMMANDS}. Used to dispatch method calls (see
    # {#method_missing} and {#call_with_namespace}) and to answer
    # {#respond_to_missing?}.
    COMMANDS = [
      NAMESPACED_COMMANDS,
      TRANSACTION_COMMANDS,
      HELPER_COMMANDS,
      ADMINISTRATIVE_COMMANDS
    ].compact.reduce(:merge)

    # Support 1.8.7 by providing a namespaced reference to Enumerable::Enumerator
    Enumerator = Enumerable::Enumerator unless defined?(::Enumerator)

    # This is used by the Redis gem to determine whether or not to display that deprecation message.
    @sadd_returns_boolean = true

    # This is used by the Redis gem to determine whether or not to display that deprecation message.
    @srem_returns_boolean = true

    class << self
      attr_accessor :sadd_returns_boolean, :srem_returns_boolean
    end

    # Sets the namespace outright; see {#namespace} for the reader (which
    # also accepts a block to yield a temporary sub-namespaced instance).
    attr_writer :namespace
    # @return [Redis, Redis::Namespace, ConnectionPool] the wrapped client
    #   that commands are ultimately dispatched to.
    attr_reader :redis
    # @return [Boolean] whether deprecation warnings (for blind passthrough
    #   and administrative commands) are printed to stderr.
    attr_accessor :warning

    # @param namespace [String, Symbol, #call] the namespace to prefix keys
    #   with. May be a +Proc+ (or any object responding to +#call+), in
    #   which case it is invoked on every use to compute the namespace
    #   dynamically (e.g. per-request/per-tenant).
    # @param options [Hash]
    # @option options [Redis, Redis::Namespace, ConnectionPool] :redis
    #   the client to wrap; defaults to a new +Redis.new+ connection.
    # @option options [Boolean] :warning whether to print deprecation
    #   warnings for blind/administrative passthrough; defaults to the
    #   inverse of the +REDIS_NAMESPACE_QUIET+ environment variable.
    # @option options [Boolean] :deprecations whether to opt in early to the
    #   2.x behavior (raising +NoMethodError+ instead of passthrough for
    #   unhandled and administrative commands); defaults to the
    #   +REDIS_NAMESPACE_DEPRECATIONS+ environment variable.
    def initialize(namespace, options = {})
      @namespace = namespace
      @redis = options[:redis] || Redis.new
      # rubocop:disable Style/DoubleNegation -- coerce to boolean, NOT negate;
      # `!x.nil?` is wrong here since an explicit `false` option must stay false.
      @warning = !!options.fetch(:warning) do
        !ENV['REDIS_NAMESPACE_QUIET']
      end
      @deprecations = !!options.fetch(:deprecations) do
        ENV['REDIS_NAMESPACE_DEPRECATIONS']
      end
      # rubocop:enable Style/DoubleNegation
      @has_new_client_method = @redis.respond_to?(:_client)
    end

    # @return [Boolean] whether early opt-in to 2.x behavior is enabled (see
    #   the +:deprecations+ option to {#initialize}).
    def deprecations?
      @deprecations
    end

    # @return [Boolean] whether deprecation warnings are printed (see the
    #   +:warning+ option to {#initialize}).
    def warning?
      @warning
    end

    # @deprecated Use {#_client} instead; this will be removed in
    #   redis-namespace 2.0.
    # @return [Redis::Client] the underlying client of {#redis}.
    def client
      if @has_new_client_method && deprecations?
        warn("The client method is deprecated as of redis-rb 4.0.0, please use the new _client " \
              "method instead. Support for the old method will be removed in redis-namespace 2.0.")
      end
      _client
    end

    # @return [Redis::Client] the underlying client of {#redis}, unwrapping
    #   any nested Redis::Namespace instances.
    def _client
      @has_new_client_method ? @redis._client : @redis.client # for redis-4.0.0
    end

    # Namespaced +TYPE key+. Defined explicitly (rather than left to
    # {method_missing}) because Ruby's own deprecated +Kernel#type+ method
    # otherwise shadows it and prevents method_missing from ever firing.
    # @param key [String]
    # @return [String] the Redis type of the (namespaced) key.
    def type(key)
      call_with_namespace(:type, key)
    end

    alias self_respond_to? respond_to?

    # @param command [Symbol, String]
    # @param include_private [Boolean]
    # @return [Boolean] whether this instance responds to +command+: false
    #   for administrative commands once {#deprecations?} is enabled,
    #   otherwise delegates to {#respond_to_missing?}.
    # rubocop:disable Style/OptionalBooleanParameter -- must match Object#respond_to?'s positional signature
    def respond_to?(command, include_private = false)
      return !deprecations? if DEPRECATED_COMMANDS.include?(command.to_s.downcase)

      respond_to_missing?(command, include_private) or super
    end
    # rubocop:enable Style/OptionalBooleanParameter

    # Namespaced +KEYS pattern+.
    # @param query [String, nil] a glob-style pattern; defaults to +'*'+
    #   (all keys in the namespace).
    # @return [Array<String>] matching keys, with the namespace stripped.
    def keys(query = nil)
      call_with_namespace(:keys, query || '*')
    end

    # Namespaced +MULTI+. Without a block this simply opens a transaction
    # (paired with a later {#exec} or +discard+ call); with a block, yields
    # a namespaced proxy for the duration of the transaction so that
    # commands issued inside the block are namespaced too.
    # @yieldparam transaction [Redis::Namespace, Redis] the object to issue
    #   transactional commands against.
    # @return [Object] the underlying Redis client's return value.
    def multi(&block)
      if block_given?
        namespaced_block(:multi, &block)
      else
        call_with_namespace(:multi)
      end
    end

    # Namespaced +PIPELINE+. Yields a namespaced proxy so that every command
    # issued inside the block is namespaced and executed as a single
    # pipeline round-trip.
    # @yieldparam pipeline [Redis::Namespace, Redis] the object to issue
    #   pipelined commands against.
    # @return [Array] the array of results, one per pipelined command.
    def pipelined(&block)
      namespaced_block(:pipelined, &block)
    end

    # Reads (or, with a block, temporarily switches to) the namespace.
    #
    # @param desired_namespace [String, Symbol, #call, nil] when given,
    #   yields a new Redis::Namespace wrapping the same underlying
    #   {#redis} connection, but scoped to +desired_namespace+ in place of
    #   (not nested under) this instance's own namespace.
    # @yieldparam temporary [Redis::Namespace] the temporarily-namespaced instance.
    # @return [String] the current namespace (resolved from a Proc if
    #   necessary); the return value of {#namespace} itself is unaffected by
    #   the block, which operates on the yielded instance.
    #
    # @example
    #   ns.namespace # => "ns"
    #   ns.namespace(:temp) { |t| t.set('foo', 'bar') } # writes "temp:foo", not "ns:temp:foo"
    def namespace(desired_namespace = nil)
      if desired_namespace
        yield Redis::Namespace.new(desired_namespace,
                                   :redis => @redis)
      end

      @namespace.respond_to?(:call) ? @namespace.call : @namespace
    end

    # @return [String] the fully-qualified, colon-joined namespace,
    #   including any namespaces of wrapped Redis::Namespace instances.
    def full_namespace
      redis.is_a?(Namespace) ? "#{redis.full_namespace}:#{namespace}" : namespace.to_s
    end

    # @return [Hash] the underlying connection info, augmented with the
    #   current +:namespace+.
    def connection
      @redis.connection.tap { |info| info[:namespace] = namespace }
    end

    # Namespaced +EXEC+, for use after a blockless {#multi}.
    # @return [Array, nil] the array of results from the transaction.
    def exec
      call_with_namespace(:exec)
    end

    # Namespaced +EVAL+. Namespaces only the keys argument (whether passed
    # positionally or via a +:keys+/+:argv+ options hash); the script and
    # +argv+ are passed through unmodified.
    # @param args [Array] script, plus either +(keys, argv)+ arrays or a
    #   +{keys:, argv:}+ options hash.
    # @return [Object] the script's return value.
    def eval(*args)
      call_with_namespace(:eval, *args)
    end
    ruby2_keywords(:eval) if respond_to?(:ruby2_keywords, true)

    # Deletes every key in this namespace, in batches of 1000, using +SCAN+
    # where the server supports it (Redis >= 2.8.0) and falling back to
    # +KEYS+ otherwise.
    #
    # This operation can run for a very long time if the namespace contains lots of keys!
    # It should be used in tests, or when the namespace is small enough
    # and you are sure you know what you are doing.
    # @return [void]
    def clear
      if warning?
        warn("This operation can run for a very long time if the namespace contains lots of keys! " \
             "It should be used in tests, or when the namespace is small enough " \
             "and you are sure you know what you are doing.")
      end

      batch_size = 1000

      if supports_scan?
        cursor = "0"
        loop do
          cursor, keys = scan(cursor, count: batch_size)
          del(*keys) unless keys.empty?
          break if cursor == "0"
        end
      else
        all_keys = keys("*")
        all_keys.each_slice(batch_size) do |keys|
          del(*keys)
        end
      end
    end

    ADMINISTRATIVE_COMMANDS.each_key do |command|
      define_method(command) do |*args, &block|
        raise NoMethodError if deprecations?

        if warning?
          warn("Passing '#{command}' command to redis as is; " \
               "administrative commands cannot be effectively namespaced " \
               "and should be called on the redis connection directly; " \
               "passthrough has been deprecated and will be removed in " \
               "redis-namespace 2.0 (at #{call_site})")
        end
        call_with_namespace(command, *args, &block)
      end
      ruby2_keywords(command) if respond_to?(:ruby2_keywords, true)
    end

    COMMANDS.each_key do |command|
      next if ADMINISTRATIVE_COMMANDS.include?(command)
      next if method_defined?(command)

      define_method(command) do |*args, &block|
        call_with_namespace(command, *args, &block)
      end
      ruby2_keywords(command) if respond_to?(:ruby2_keywords, true)
    end

    # Dispatches any command not already defined as a real method. This
    # fires for commands that are known (in {COMMANDS}) but were skipped by
    # the +define_method+ loops above because a hand-written method already
    # exists (e.g. via +send('SET', ...)+, which bypasses normal dispatch),
    # and — until {#deprecations?} is enabled — for entirely unknown
    # commands, which are passed through to {#redis} unmodified (with a
    # deprecation warning) rather than namespaced.
    # @return [Object] the command's result.
    # @raise [NoMethodError] if the command is unknown and {#deprecations?}
    #   is enabled, or if {#redis} doesn't respond to it either.
    def method_missing(command, *args, &block)
      normalized_command = command.to_s.downcase

      if COMMANDS.include?(normalized_command)
        send(normalized_command, *args, &block)
      elsif @redis.respond_to?(normalized_command) && !deprecations?
        # blind passthrough is deprecated and will be removed in 2.0
        # redis-namespace does not know how to handle this command.
        # Passing it to @redis as is, where redis-namespace shows
        # a warning message if @warning is set.
        if warning?
          warn("Passing '#{command}' command to redis as is; blind " \
               "passthrough has been deprecated and will be removed in " \
               "redis-namespace 2.0 (at #{call_site})")
        end

        wrapped_send(@redis, command, args, &block)
      else
        super
      end
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

    # @return [String] a human-readable representation including the
    #   redis-namespace and redis-rb versions, the underlying connection id,
    #   and the {#full_namespace}.
    def inspect
      "<#{self.class.name} v#{VERSION} with client v#{Redis::VERSION} "\
      "for #{@redis.id}/#{full_namespace}>"
    end

    # @return [Boolean] whether {#method_missing} would be able to handle
    #   +command+: true for anything in {COMMANDS}, or (unless
    #   {#deprecations?} is enabled) anything {#redis} itself responds to.
    def respond_to_missing?(command, include_all = false)
      normalized_command = command.to_s.downcase

      if COMMANDS.include?(normalized_command)
        true
      elsif !deprecations? && redis.respond_to?(command, include_all)
        true
      else
        defined?(super) && super
      end
    end

    # The core of Redis::Namespace: looks up how +command+'s arguments and
    # return value should be namespaced (see {COMMANDS}), rewrites the
    # arguments accordingly, dispatches the command to {#redis}, and strips
    # the namespace back out of the result.
    #
    # This is a public method (rather than a private implementation detail)
    # so that every generated command method (see the +define_method+ loops
    # above) and {#method_missing} can call it, and so that callers can
    # invoke a known command by name directly if needed.
    #
    # @param command [Symbol, String] a key in {COMMANDS}.
    # @param args [Array] the command's arguments, as they would be passed
    #   to the underlying {#redis} client.
    # @return [Object] the (de-namespaced) result of the command.
    # @raise [RuntimeError] if +command+ is not a key in {COMMANDS}.
    def call_with_namespace(command, *args, &block)
      handling = COMMANDS[command.to_s.downcase]

      raise("Redis::Namespace does not know how to handle '#{command}'.") if handling.nil?

      (before, after) = handling

      # Modify the local *args array in-place, no need to copy it.
      args.map! { |arg| clone_args(arg) }

      # Add the namespace to any parameters that are keys.
      case before
      when :first
        args[0] = add_namespace(args[0]) if args[0]
        args[-1] = ruby2_keywords_hash(args[-1]) if args[-1].is_a?(Hash)
      when :all
        args = add_namespace(args)
      when :exclude_first
        first = args.shift
        args = add_namespace(args)
        args.unshift(first) if first
      when :exclude_last
        last = args.pop unless args.length == 1
        args = add_namespace(args)
        args.push(last) if last
      when :exclude_options
        if args.last.is_a?(Hash)
          last = ruby2_keywords_hash(args.pop)
          args = add_namespace(args)
          args.push(last)
        else
          args = add_namespace(args)
        end
      when :alternate
        args = args.flatten
        args.each_with_index { |a, i| args[i] = add_namespace(a) if i.even? }
      when :sort
        args[0] = add_namespace(args[0]) if args[0]
        if args[1].is_a?(Hash)
          %i[by store].each do |key|
            args[1][key] = add_namespace(args[1][key]) if args[1][key]
          end

          args[1][:get] = Array(args[1][:get])

          args[1][:get].each_index do |i|
            args[1][:get][i] = add_namespace(args[1][:get][i]) unless args[1][:get][i] == "#"
          end
          args[1] = ruby2_keywords_hash(args[1])
        end
      when :eval_style
        # redis.eval() and evalsha() can either take the form:
        #
        #   redis.eval(script, [key1, key2], [argv1, argv2])
        #
        # Or:
        #
        #   redis.eval(script, :keys => ['k1', 'k2'], :argv => ['arg1', 'arg2'])
        #
        # This is a tricky + annoying special case, where we only want the `keys`
        # argument to be namespaced.
        if args.last.is_a?(Hash)
          args.last[:keys] = add_namespace(args.last[:keys])
        else
          args[1] = add_namespace(args[1])
        end
      when :scan_style
        options = (args.last.is_a?(Hash) ? args.pop : {})
        options[:match] = add_namespace(options.fetch(:match, '*'))
        args << ruby2_keywords_hash(options)

        if block
          original_block = block
          block = proc { |key| original_block.call rem_namespace(key) }
        end
      end

      # Dispatch the command to Redis and store the result.
      result = wrapped_send(@redis, command, args, &block)

      # Don't try to remove namespace from a Redis::Future, you can't.
      return result if result.is_a?(Redis::Future)

      # Remove the namespace from results that are keys.
      case after
      when :all
        result = rem_namespace(result)
      when :first
        result[0] = rem_namespace(result[0]) if result
      when :second
        result[1] = rem_namespace(result[1]) if result
      end

      result
    end
    ruby2_keywords(:call_with_namespace) if respond_to?(:ruby2_keywords, true)

    protected

    attr_writer :redis

    private

    if Hash.respond_to?(:ruby2_keywords_hash)
      def ruby2_keywords_hash(kwargs)
        Hash.ruby2_keywords_hash(kwargs)
      end
    else
      # :nocov:
      # Hash.ruby2_keywords_hash was added in Ruby 2.7; this fallback keeps
      # required_ruby_version's older supported interpreters (< 2.7) working,
      # but can't be exercised while running the suite on a single, newer
      # Ruby, so it's excluded from coverage accounting here.
      def ruby2_keywords_hash(kwargs)
        kwargs
      end
      # :nocov:
    end

    def wrapped_send(redis_client, command, args = [], &block)
      # Compare by class name (not `is_a?(ConnectionPool)`) so this works
      # without requiring the optional `connection_pool` gem to be loaded.
      # rubocop:disable Style/ClassEqualityComparison
      if redis_client.class.name == "ConnectionPool"
        # rubocop:enable Style/ClassEqualityComparison
        redis_client.with do |pool_connection|
          pool_connection.send(command, *args, &block)
        end
      else
        redis_client.send(command, *args, &block)
      end
    end

    # Avoid modifying the caller's (pass-by-reference) arguments.
    def clone_args(arg)
      if arg.is_a?(Array)
        arg.map { |sub_arg| clone_args(sub_arg) }
      elsif arg.is_a?(Hash)
        Hash[arg.map { |k, v| [clone_args(k), clone_args(v)] }]
      else
        arg # Some objects (e.g. symbol) can't be dup'd.
      end
    end

    def call_site
      caller.reject { |l| l.start_with?(__FILE__) }.first
    end

    def namespaced_block(command, &block)
      if block.arity.zero?
        wrapped_send(redis, command, &block)
      else
        outer_block = proc { |r|
          copy = dup
          copy.redis = r
          yield copy
        }
        wrapped_send(redis, command, &outer_block)
      end
    end

    def add_namespace(key)
      return key unless key && namespace

      case key
      when Array
        key.map! { |k| add_namespace k }
      when Hash
        key.keys.each { |k| key[add_namespace(k)] = key.delete(k) }
        key
      else
        "#{namespace}:#{key}"
      end
    end

    def rem_namespace(key)
      return key unless key && namespace

      case key
      when Array
        key.map { |k| rem_namespace k }
      when Hash
        Hash[*key.map { |k, v| [rem_namespace(k), v] }.flatten]
      when Enumerator
        create_enumerator do |yielder|
          key.each { |k| yielder.yield rem_namespace(k) }
        end
      else
        key.to_s.sub(/\A#{namespace}:/, '')
      end
    end

    def create_enumerator(&block)
      # Enumerator in 1.8.7 *requires* a single argument, so we need to use
      # its Generator class, which matches the block syntax of 1.9.x's
      # Enumerator class.
      if RUBY_VERSION.start_with?('1.8')
        # :nocov:
        require 'generator' unless defined?(Generator)
        Generator.new(&block).to_enum
        # :nocov:
      else
        Enumerator.new(&block)
      end
    end

    def supports_scan?
      redis_version = @redis.info["redis_version"]
      Gem::Version.new(redis_version) >= Gem::Version.new("2.8.0")
    end
  end
end
