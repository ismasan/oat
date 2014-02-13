require 'spec_helper'
require 'oat/adapters/json_api'

describe Oat::Adapters::JsonAPI do

  include Fixtures

  subject{ serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::JsonAPI) }

  describe '#to_hash' do
    it 'produces a JSON-API compliant hash' do
      payload = subject.to_hash
      # embedded friends
      payload[:linked][:friends][0].tap do |f|
        f[:id].should == friend.id
        f[:name].should == friend.name
        f[:age].should == friend.age
        f[:controller_name].should == 'some_controller'
        f[:links][:self].should == "http://foo.bar.com/#{friend.id}"
      end

      # embedded manager
      payload[:linked][:managers][0].tap do |m|
        m[:id].should == manager.id
        m[:name].should == manager.name
        m[:age].should  == manager.age
        m[:links][:self].should == "http://foo.bar.com/#{manager.id}"
      end

      payload[:users][0].tap do |h|
        h[:id].should == user.id
        h[:name].should == user.name
        h[:age].should == user.age
        h[:controller_name].should == 'some_controller'
        # links
        h[:links][:self].should == "http://foo.bar.com/#{user.id}"
        # these links are added by embedding entities
        h[:links][:manager].should == manager.id
        h[:links][:friends].should == [friend.id]
      end
    end

    context 'with a nil entity relationship' do
      let(:manager) { nil }

      it 'produces a JSON-API compliant hash' do
        payload = subject.to_hash
        # embedded friends
        payload[:linked][:friends][0].tap do |f|
          f[:id].should == friend.id
          f[:name].should == friend.name
          f[:age].should == friend.age
          f[:controller_name].should == 'some_controller'
          f[:links][:self].should == "http://foo.bar.com/#{friend.id}"
        end

        # embedded manager
        payload[:linked].fetch(:managers).should be_empty

        payload[:users][0].tap do |h|
          h[:id].should == user.id
          h[:name].should == user.name
          h[:age].should == user.age
          h[:controller_name].should == 'some_controller'
          # links
          h[:links][:self].should == "http://foo.bar.com/#{user.id}"
          # these links are added by embedding entities
          h[:links].should_not include(:manager)
          h[:links][:friends].should == [friend.id]
        end
      end
    end
  end
end
