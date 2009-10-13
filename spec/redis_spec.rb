require File.dirname(__FILE__) + '/spec_helper'
require 'redis/namespace'
require 'logger'

describe "redis" do
  before(:all) do
    # use database 15 for testing so we dont accidentally step on you real data
    @r = Redis.new :db => 15
  end

  before(:each) do
    @r['foo'] = 'bar'
  end

  after(:each) do
    @r.flushdb
  end

  after(:all) do
    @r.quit
  end
  it "should be able to use a namespace" do
    r = Redis::Namespace.new(:ns, :redis => @r)
    r.flushdb

    r['foo'].should == nil
    r['foo'] = 'chris'
    r['foo'].should == 'chris'
    @r['foo'] = 'bob'
    @r['foo'].should == 'bob'

    r.incr('counter', 2)
    r['counter'].to_i.should == 2
    @r['counter'].should == nil
  end

  it "should be able to use a namespace with mget" do
    r = Redis::Namespace.new(:ns, :redis => @r)

    r['foo'] = 1000
    r['bar'] = 2000
    r.mapped_mget('foo', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
    r.mapped_mget('foo', 'baz', 'bar').should == { 'foo' => '1000', 'bar' => '2000' }
  end
end
