require File.dirname(__FILE__) + '/../spec_helper'

describe Redis::Namespace do
  let(:namespaced_redis) { Redis::Namespace.new(namespace, :redis => double) }

  describe "#namespace" do
    subject { namespaced_redis.namespace }

    context "with a callable namespace" do
      let(:namespace) { double(:call => "the callable result") }

      it { should == "the callable result" }
    end

    context "with a string namespace" do
      let(:namespace) { "namespace" }

      it { should == "namespace" }
    end

    context "with a symbol namespace" do
      let(:namespace) { :ns }

      it { should == :ns }
    end
  end
end
