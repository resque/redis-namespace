require File.dirname(__FILE__) + '/spec_helper'

describe "redis" do
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
    @namespaced.client.should == @redis.client
  end

  it "should be able to use a namespace" do
    @namespaced['foo'].should == nil
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should == 'chris'
    @redis['foo'] = 'bob'
    @redis['foo'].should == 'bob'

    @namespaced.incrby('counter', 2)
    @namespaced['counter'].to_i.should == 2
    @redis['counter'].should == nil
    @namespaced.type('counter').should == 'string'
  end

  it "should be able to use a namespace with bpop" do
    @namespaced.rpush "foo", "string"
    @namespaced.rpush "foo", "ns:string"
    @namespaced.blpop("foo", 1).should == ["foo", "string"]
    @namespaced.blpop("foo", 1).should == ["foo", "ns:string"]
    @namespaced.blpop("foo", 1).should == nil
  end

  it "should be able to use a namespace with del" do
    @namespaced['foo'] = 1000
    @namespaced['bar'] = 2000
    @namespaced['baz'] = 3000
    @namespaced.del 'foo'
    @namespaced['foo'].should == nil
    @namespaced.del 'bar', 'baz'
    @namespaced['bar'].should == nil
    @namespaced['baz'].should == nil
  end

  it 'should be able to use a namespace with append' do
    @namespaced['foo'] = 'bar'
    @namespaced.append('foo','n').should == 4
    @namespaced['foo'].should == 'barn'
    @redis['foo'].should == 'bar'
  end

  it 'should be able to use a namespace with brpoplpush' do
    @namespaced.lpush('foo','bar')
    @namespaced.brpoplpush('foo','bar',0).should == 'bar'
    @namespaced.lrange('foo',0,-1).should == []
    @namespaced.lrange('bar',0,-1).should == ['bar']
  end

  it 'should be able to use a namespace with getbit' do
    @namespaced.set('foo','bar')
    @namespaced.getbit('foo',1).should == 1
  end

  it 'should be able to use a namespace with getrange' do
    @namespaced.set('foo','bar')
    @namespaced.getrange('foo',0,-1).should == 'bar'
  end

  it 'should be able to use a namespace with linsert' do
    @namespaced.rpush('foo','bar')
    @namespaced.rpush('foo','barn')
    @namespaced.rpush('foo','bart')
    @namespaced.linsert('foo','BEFORE','barn','barf').should == 4
    @namespaced.lrange('foo',0,-1).should == ['bar','barf','barn','bart']
  end

  it 'should be able to use a namespace with lpushx' do
    @namespaced.lpushx('foo','bar').should == 0
    @namespaced.lpush('foo','boo')
    @namespaced.lpushx('foo','bar').should == 2
    @namespaced.lrange('foo',0,-1).should == ['bar','boo']
  end

  it 'should be able to use a namespace with rpushx' do
    @namespaced.rpushx('foo','bar').should == 0
    @namespaced.lpush('foo','boo')
    @namespaced.rpushx('foo','bar').should == 2
    @namespaced.lrange('foo',0,-1).should == ['boo','bar']
  end

  it 'should be able to use a namespace with setbit' do
    @namespaced.setbit('virgin_key', 1, 1)
    @namespaced.exists('virgin_key').should be_true
    @namespaced.get('virgin_key').should == @namespaced.getrange('virgin_key',0,-1)
  end

  it 'should be able to use a namespace with setrange' do
    @namespaced.setrange('foo', 0, 'bar')
    @namespaced['foo'].should == 'bar'

    @namespaced.setrange('bar', 2, 'foo')
    @namespaced['bar'].should == "\000\000foo"
  end

  it "should be able to use a namespace with mget" do
    @namespaced['foo'] = 1000
    @namespaced['bar'] = 2000
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == {'foo'=>'1000', 'bar'=>'2000', 'baz' => nil}
  end

  it "should be able to use a namespace with mset" do
    @namespaced.mset('foo', '1000', 'bar', '2000')
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == { 'foo' => '1000', 'bar' => '2000', 'baz' => nil}
  end

  it "should be able to use a namespace with msetnx" do
    @namespaced.msetnx('foo', '1000', 'bar', '2000')
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == { 'foo' => '1000', 'bar' => '2000', 'baz' => nil}
  end

  it "should be able to use a namespace with hashes" do
    @namespaced.hset('foo', 'key', 'value')
    @namespaced.hset('foo', 'key1', 'value1')
    @namespaced.hget('foo', 'key').should == 'value'
    @namespaced.hgetall('foo').should == {'key' => 'value', 'key1' => 'value1'}
    @namespaced.hlen('foo').should == 2
    @namespaced.hkeys('foo').should == ['key', 'key1']
    @namespaced.hmset('bar', 'key', 'value', 'key1', 'value1')
    @namespaced.hmget('bar', 'key', 'key1')
    @namespaced.hmset('bar', 'a_number', 1)
    @namespaced.hmget('bar', 'a_number').should == ['1']
    @namespaced.hincrby('bar', 'a_number', 3)
    @namespaced.hmget('bar', 'a_number').should == ['4']
    @namespaced.hgetall('bar').should == {'key' => 'value', 'key1' => 'value1', 'a_number' => '4'}

    @namespaced.hsetnx('foonx','nx',10).should be_true
    @namespaced.hsetnx('foonx','nx',12).should be_false
    @namespaced.hget('foonx','nx').should == "10"
    @namespaced.hkeys('foonx').should     == %w{ nx }
    @namespaced.hvals('foonx').should     == %w{ 10 }
    @namespaced.mapped_hmset('baz', {'key' => 'value', 'key1' => 'value1', 'a_number' => 4})
    @namespaced.hgetall('baz').should == {'key' => 'value', 'key1' => 'value1', 'a_number' => '4'}
  end

  it "should properly intersect three sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('foo', 3)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    @namespaced.sadd('baz', 3)
    @namespaced.sinter('foo', 'bar', 'baz').should == %w( 3 )
  end

  it "should properly union two sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    @namespaced.sunion('foo', 'bar').sort.should == %w( 1 2 3 4 )
  end

  it "should properly union two sorted sets with options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'], :weights => [2, 1])
    @namespaced.zrevrange('union', 0, -1).should == %w( 2 4 3 1 )
  end

  it "should properly union two sorted sets without options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'])
    @namespaced.zrevrange('union', 0, -1).should == %w( 4 2 3 1 )
  end

  it "should add namespace to sort" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.set('weight_1', 2)
    @namespaced.set('weight_2', 1)
    @namespaced.set('value_1', 'a')
    @namespaced.set('value_2', 'b')

    @namespaced.sort('foo').should == %w( 1 2 )
    @namespaced.sort('foo', :limit => [0, 1]).should == %w( 1 )
    @namespaced.sort('foo', :order => 'desc').should == %w( 2 1 )
    @namespaced.sort('foo', :by => 'weight_*').should == %w( 2 1 )
    @namespaced.sort('foo', :get => 'value_*').should == %w( a b )

    @namespaced.sort('foo', :store => 'result')
    @namespaced.lrange('result', 0, -1).should == %w( 1 2 )
  end

  it "should yield the correct list of keys" do
    @namespaced["foo"] = 1
    @namespaced["bar"] = 2
    @namespaced["baz"] = 3
    @namespaced.keys("*").sort.should == %w( bar baz foo )
    @namespaced.keys.sort.should == %w( bar baz foo )
  end

  it "can change its namespace" do
    @namespaced['foo'].should == nil
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should == 'chris'

    @namespaced.namespace.should == :ns
    @namespaced.namespace = :spec
    @namespaced.namespace.should == :spec

    @namespaced['foo'].should == nil
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should == 'chris'
  end

  it "should respond to :namespace=" do
    @namespaced.respond_to?(:namespace=).should == true
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
      @redis.llen('ns:bar').should == 1
    end

    it "should support command aliases (zset_add)" do
      @namespaced.zset_add('bar', 1, 'quux')
      @redis.zcard('ns:bar').should == 1
    end
  end
end
