require 'spec_helper'
require 'oat/adapters/hal'

describe Oat::Adapters::HAL do

  include Fixtures

  before do
    serializer_class.adapter Oat::Adapters::HAL
  end

  describe '#to_hash' do
    it 'produces a HAL-compliant hash' do
      serializer = serializer_class.new(user, {name: 'some_controller'})
      serializer.to_hash.tap do |h|
        # properties
        h[:id].should == user.id
        h[:name].should == user.name
        h[:age].should == user.age
        h[:controller_name].should == 'some_controller'
        # links
        h[:_links][:self][:href].should == "http://foo.bar.com/#{user.id}"
        # embedded manager
        h[:_embedded][:manager].tap do |m|
          m[:name].should == manager.name
          m[:age].should  == manager.age
          m[:_links][:self][:href].should == "http://foo.bar.com/#{manager.id}"
        end
        # embedded friends
        h[:_embedded][:friends].size.should == 1
        h[:_embedded][:friends][0].tap do |f|
          f[:id].should == friend.id
          f[:name].should == friend.name
          f[:age].should == friend.age
          f[:controller_name].should == 'some_controller'
          f[:_links][:self][:href].should == "http://foo.bar.com/#{friend.id}"
        end
      end
    end
  end
end