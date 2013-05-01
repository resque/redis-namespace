require File.dirname(__FILE__) + '/spec_helper'

describe "redis" do
  @redis_version = Gem::Version.new(Redis.current.info["redis_version"])

  before(:all) do
    # use database 15 for testing so we dont accidentally step on your real data
    @redis = Redis.new :db => 15
  end

  before(:each) do
    @namespaced = Redis::Namespace.new(:ns, :redis => @redis)
    @namespaced.flushdb
    @redis['foo'] = 'bar'
  end

  after(:each) do
    @redis.flushdb
  end

  after(:all) do
    @redis.quit
  end

  it "proxies `client` to the client" do
    @namespaced.client.should eq(@redis.client)
  end

  it "should be able to use a namespace" do
    @namespaced['foo'].should eq(nil)
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should eq('chris')
    @redis['foo'] = 'bob'
    @redis['foo'].should eq('bob')

    @namespaced.incrby('counter', 2)
    @namespaced['counter'].to_i.should eq(2)
    @redis['counter'].should eq(nil)
    @namespaced.type('counter').should eq('string')
  end

  it "should be able to use a namespace with bpop" do
    @namespaced.rpush "foo", "string"
    @namespaced.rpush "foo", "ns:string"
    @namespaced.rpush "foo", "string_no_timeout"
    @namespaced.blpop("foo", 1).should eq(["foo", "string"])
    @namespaced.blpop("foo", 1).should eq(["foo", "ns:string"])
    @namespaced.blpop("foo").should eq(["foo", "string_no_timeout"])
    @namespaced.blpop("foo", 1).should eq(nil)
  end

  it "should be able to use a namespace with del" do
    @namespaced['foo'] = 1000
    @namespaced['bar'] = 2000
    @namespaced['baz'] = 3000
    @namespaced.del 'foo'
    @namespaced['foo'].should eq(nil)
    @namespaced.del 'bar', 'baz'
    @namespaced['bar'].should eq(nil)
    @namespaced['baz'].should eq(nil)
  end

  it 'should be able to use a namespace with append' do
    @namespaced['foo'] = 'bar'
    @namespaced.append('foo','n').should eq(4)
    @namespaced['foo'].should eq('barn')
    @redis['foo'].should eq('bar')
  end

  it 'should be able to use a namespace with brpoplpush' do
    @namespaced.lpush('foo','bar')
    @namespaced.brpoplpush('foo','bar',0).should eq('bar')
    @namespaced.lrange('foo',0,-1).should eq([])
    @namespaced.lrange('bar',0,-1).should eq(['bar'])
  end

  it 'should be able to use a namespace with getbit' do
    @namespaced.set('foo','bar')
    @namespaced.getbit('foo',1).should eq(1)
  end

  it 'should be able to use a namespace with getrange' do
    @namespaced.set('foo','bar')
    @namespaced.getrange('foo',0,-1).should eq('bar')
  end

  it 'should be able to use a namespace with linsert' do
    @namespaced.rpush('foo','bar')
    @namespaced.rpush('foo','barn')
    @namespaced.rpush('foo','bart')
    @namespaced.linsert('foo','BEFORE','barn','barf').should eq(4)
    @namespaced.lrange('foo',0,-1).should eq(['bar','barf','barn','bart'])
  end

  it 'should be able to use a namespace with lpushx' do
    @namespaced.lpushx('foo','bar').should eq(0)
    @namespaced.lpush('foo','boo')
    @namespaced.lpushx('foo','bar').should eq(2)
    @namespaced.lrange('foo',0,-1).should eq(['bar','boo'])
  end

  it 'should be able to use a namespace with rpushx' do
    @namespaced.rpushx('foo','bar').should eq(0)
    @namespaced.lpush('foo','boo')
    @namespaced.rpushx('foo','bar').should eq(2)
    @namespaced.lrange('foo',0,-1).should eq(['boo','bar'])
  end

  it 'should be able to use a namespace with setbit' do
    @namespaced.setbit('virgin_key', 1, 1)
    @namespaced.exists('virgin_key').should be_true
    @namespaced.get('virgin_key').should eq(@namespaced.getrange('virgin_key',0,-1))
  end

  it 'should be able to use a namespace with setrange' do
    @namespaced.setrange('foo', 0, 'bar')
    @namespaced['foo'].should eq('bar')

    @namespaced.setrange('bar', 2, 'foo')
    @namespaced['bar'].should eq("\000\000foo")
  end

  it "should be able to use a namespace with mget" do
    @namespaced['foo'] = 1000
    @namespaced['bar'] = 2000
    @namespaced.mapped_mget('foo', 'bar').should eq({ 'foo' => '1000', 'bar' => '2000' })
    @namespaced.mapped_mget('foo', 'baz', 'bar').should eq({'foo'=>'1000', 'bar'=>'2000', 'baz' => nil})
  end

  it "should be able to use a namespace with mset" do
    @namespaced.mset('foo', '1000', 'bar', '2000')
    @namespaced.mapped_mget('foo', 'bar').should eq({ 'foo' => '1000', 'bar' => '2000' })
    @namespaced.mapped_mget('foo', 'baz', 'bar').should eq({ 'foo' => '1000', 'bar' => '2000', 'baz' => nil})
    @namespaced.mapped_mset('foo' => '3000', 'bar' => '5000')
    @namespaced.mapped_mget('foo', 'bar').should eq({ 'foo' => '3000', 'bar' => '5000' })
    @namespaced.mapped_mget('foo', 'baz', 'bar').should eq({ 'foo' => '3000', 'bar' => '5000', 'baz' => nil})
  end

  it "should be able to use a namespace with msetnx" do
    @namespaced.msetnx('foo', '1000', 'bar', '2000')
    @namespaced.mapped_mget('foo', 'bar').should eq({ 'foo' => '1000', 'bar' => '2000' })
    @namespaced.mapped_mget('foo', 'baz', 'bar').should eq({ 'foo' => '1000', 'bar' => '2000', 'baz' => nil})
  end

  it "should be able to use a namespace with mapped_msetnx" do
    puts @namespaced.keys.inspect
    @namespaced.set('foo','1')
    @namespaced.mapped_msetnx('foo'=>'1000', 'bar'=>'2000').should be_false
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1', 'bar' => nil }
    @namespaced.mapped_msetnx('bar'=>'2000', 'baz'=>'1000').should be_true
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1', 'bar' => '2000' }
  end

  it "should be able to use a namespace with hashes" do
    @namespaced.hset('foo', 'key', 'value')
    @namespaced.hset('foo', 'key1', 'value1')
    @namespaced.hget('foo', 'key').should eq('value')
    @namespaced.hgetall('foo').should eq({'key' => 'value', 'key1' => 'value1'})
    @namespaced.hlen('foo').should eq(2)
    @namespaced.hkeys('foo').should eq(['key', 'key1'])
    @namespaced.hmset('bar', 'key', 'value', 'key1', 'value1')
    @namespaced.hmget('bar', 'key', 'key1')
    @namespaced.hmset('bar', 'a_number', 1)
    @namespaced.hmget('bar', 'a_number').should eq(['1'])
    @namespaced.hincrby('bar', 'a_number', 3)
    @namespaced.hmget('bar', 'a_number').should eq(['4'])
    @namespaced.hgetall('bar').should eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})

    @namespaced.hsetnx('foonx','nx',10).should be_true
    @namespaced.hsetnx('foonx','nx',12).should be_false
    @namespaced.hget('foonx','nx').should eq("10")
    @namespaced.hkeys('foonx').should eq(%w{ nx })
    @namespaced.hvals('foonx').should eq(%w{ 10 })
    @namespaced.mapped_hmset('baz', {'key' => 'value', 'key1' => 'value1', 'a_number' => 4})
    @namespaced.mapped_hmget('baz', 'key', 'key1', 'a_number').should eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})
    @namespaced.hgetall('baz').should eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})
  end

  it "should properly intersect three sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('foo', 3)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    @namespaced.sadd('baz', 3)
    @namespaced.sinter('foo', 'bar', 'baz').should eq(%w( 3 ))
  end

  it "should properly union two sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    @namespaced.sunion('foo', 'bar').sort.should eq(%w( 1 2 3 4 ))
  end

  it "should properly union two sorted sets with options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'], :weights => [2, 1])
    @namespaced.zrevrange('union', 0, -1).should eq(%w( 2 4 3 1 ))
  end

  it "should properly union two sorted sets without options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'])
    @namespaced.zrevrange('union', 0, -1).should eq(%w( 4 2 3 1 ))
  end

  it "should add namespace to sort" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.set('weight_1', 2)
    @namespaced.set('weight_2', 1)
    @namespaced.set('value_1', 'a')
    @namespaced.set('value_2', 'b')

    @namespaced.sort('foo').should eq(%w( 1 2 ))
    @namespaced.sort('foo', :limit => [0, 1]).should eq(%w( 1 ))
    @namespaced.sort('foo', :order => 'desc').should eq(%w( 2 1 ))
    @namespaced.sort('foo', :by => 'weight_*').should eq(%w( 2 1 ))
    @namespaced.sort('foo', :get => 'value_*').should eq(%w( a b ))
    @namespaced.sort('foo', :get => '#').should eq(%w( 1 2 ))
    @namespaced.sort('foo', :get => ['#', 'value_*']).should eq([["1", "a"], ["2", "b"]])

    @namespaced.sort('foo', :store => 'result')
    @namespaced.lrange('result', 0, -1).should eq(%w( 1 2 ))
  end

  it "should yield the correct list of keys" do
    @namespaced["foo"] = 1
    @namespaced["bar"] = 2
    @namespaced["baz"] = 3
    @namespaced.keys("*").sort.should eq(%w( bar baz foo ))
    @namespaced.keys.sort.should eq(%w( bar baz foo ))
  end

  it "should add namepsace to multi blocks" do
    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.multi do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    @namespaced.hgetall("foo").should eq({"key1" => "value1"})
  end

  it "should add namespace to pipelined blocks" do
    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.pipelined do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    @namespaced.hgetall("foo").should eq({"key1" => "value1"})
  end

  it "should returned response array from pipelined block" do
    @namespaced.mset "foo", "bar", "key", "value"
    result = @namespaced.pipelined do |r|
      r["foo"]
      r["key"]
    end
    result.should eq(["bar", "value"])
  end

  it "can change its namespace" do
    @namespaced['foo'].should eq(nil)
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should eq('chris')

    @namespaced.namespace.should eq(:ns)
    @namespaced.namespace = :spec
    @namespaced.namespace.should eq(:spec)

    @namespaced['foo'].should eq(nil)
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should eq('chris')
  end

  it "can accept a temporary namespace" do
    @namespaced.namespace.should eq(:ns)
    @namespaced['foo'].should eq(nil)

    @namespaced.namespace(:spec) do |temp_ns|
      temp_ns.namespace.should eq(:spec)
      temp_ns['foo'].should eq(nil)
      temp_ns['foo'] = 'jake'
      temp_ns['foo'].should eq('jake')
    end

    @namespaced.namespace.should eq(:ns)
    @namespaced['foo'].should eq(nil)
  end

  it "should respond to :namespace=" do
    @namespaced.respond_to?(:namespace=).should eq(true)
  end

  it "should respond to :warning=" do
    @namespaced.respond_to?(:warning=).should == true
  end

  it "should warn against unknown commands if :warning is true" do
    @namespaced.warning = true
    capture_stderr {
      @namespaced.unknown('foo')
    }.should == "Passing 'unknown' command to redis as is."
  end

  # Redis 2.6 RC reports its version as 2.5.
  if @redis_version >= Gem::Version.new("2.5.0")
    describe "redis 2.6 commands" do
      it "should namespace bitcount" do
        pending "awaiting implementaton of command in redis gem"
      end

      it "should namespace bitop" do
        pending "awaiting implementaton of command in redis gem"
      end

      it "should namespace dump" do
        pending "awaiting implementaton of command in redis gem"
      end

      it "should namespace hincrbyfloat" do
        @namespaced.hset('mykey', 'field', 10.50)
        @namespaced.hincrbyfloat('mykey', 'field', 0.1).should eq(10.6)
      end

      it "should namespace incrbyfloat" do
        @namespaced.set('mykey', 10.50)
        @namespaced.incrbyfloat('mykey', 0.1).should eq(10.6)
      end

      it "should namespace object" do
        @namespaced.set('foo', 1000)
        @namespaced.object('encoding', 'foo').should eq('int')
      end

      it "should namespace persist" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.expire('mykey', 60)
        @namespaced.persist('mykey').should eq(true)
        @namespaced.ttl('mykey').should eq(-1)
      end

      it "should namespace pexpire" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.pexpire('mykey', 60000).should eq(true)
      end

      it "should namespace pexpireat" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.pexpire('mykey', 1555555555005).should eq(true)
      end

      it "should namespace psetex" do
        @namespaced.psetex('mykey', 10000, 'Hello').should eq('OK')
        @namespaced.get('mykey').should eq('Hello')
      end

      it "should namespace pttl" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.expire('mykey', 1)
        @namespaced.pttl('mykey').should >= 0
      end

      it "should namespace restore" do
        pending "awaiting implementaton of command in redis gem"
      end

      it "should namespace eval keys passed in as array args" do
        @namespaced.
          eval("return {KEYS[1], KEYS[2]}", %w[k1 k2], %w[arg1 arg2]).
          should eq(%w[ns:k1 ns:k2])
      end

      it "should namespace eval keys passed in as hash args" do
        @namespaced.
          eval("return {KEYS[1], KEYS[2]}", :keys => %w[k1 k2], :argv => %w[arg1 arg2]).
          should eq(%w[ns:k1 ns:k2])
      end

      context '#evalsha' do
        let!(:sha) do
          @namespaced.script(:load, "return {KEYS[1], KEYS[2]}")
        end

        it "should namespace evalsha keys passed in as array args" do
          @namespaced.
            evalsha(sha, %w[k1 k2], %w[arg1 arg2]).
            should eq(%w[ns:k1 ns:k2])
        end

        it "should namespace evalsha keys passed in as hash args" do
          @namespaced.
            evalsha(sha, :keys => %w[k1 k2], :argv => %w[arg1 arg2]).
            should eq(%w[ns:k1 ns:k2])
        end
      end
    end
  end

  # Only test aliasing functionality for Redis clients that support aliases.
  unless Redis::Namespace::ALIASES.empty?
    it "should support command aliases (delete)" do
      @namespaced.delete('foo')
      @redis.should_not have_key('ns:foo')
    end

    it "should support command aliases (set_add)" do
      @namespaced.set_add('bar', 'quux')
      @namespaced.smembers('bar').should include('quux')
    end

    it "should support command aliases (push_head)" do
      @namespaced.push_head('bar', 'quux')
      @redis.llen('ns:bar').should eq(1)
    end

    it "should support command aliases (zset_add)" do
      @namespaced.zset_add('bar', 1, 'quux')
      @redis.zcard('ns:bar').should eq(1)
    end
  end
end
