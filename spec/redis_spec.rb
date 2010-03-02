require File.dirname(__FILE__) + '/spec_helper'
require 'redis/namespace'
require 'logger'

describe "redis" do
  before(:all) do
    # use database 15 for testing so we dont accidentally step on you real data
    @redis = Redis.new :db => 15
    @namespaced = Redis::Namespace.new(:ns, :redis => @redis)
  end

  before(:each) do
    @namespaced.flushdb
    @redis['foo'] = 'bar'
  end

  after(:each) do
    @redis.flushdb
  end

  after(:all) do
    @redis.quit
  end

  it "should be able to use a namespace" do
    @namespaced['foo'].should == nil
    @namespaced['foo'] = 'chris'
    @namespaced['foo'].should == 'chris'
    @redis['foo'] = 'bob'
    @redis['foo'].should == 'bob'

    @namespaced.incr('counter', 2)
    @namespaced['counter'].to_i.should == 2
    @redis['counter'].should == nil
    @namespaced.type('counter').should == 'string'
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

  it "should be able to use a namespace with mget" do
    @namespaced['foo'] = 1000
    @namespaced['bar'] = 2000
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == {'foo'=>'1000', 'bar'=>'2000'}
  end

  it "should be able to use a namespace with mset" do
    @namespaced.mset('foo' => '1000', 'bar' => '2000')
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == { 'foo' => '1000', 'bar' => '2000'}
  end

  it "should be able to use a namespace with msetnx" do
    @namespaced.msetnx('foo' => '1000', 'bar' => '2000')
    @namespaced.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    @namespaced.mapped_mget('foo', 'baz', 'bar').should == { 'foo' => '1000', 'bar' => '2000'}
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
end
