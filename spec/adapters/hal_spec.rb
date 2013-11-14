require 'spec_helper'
require 'oat/adapters/hal'

describe Oat::Adapters::HAL do

  before do
    @serializer_class = Class.new(Oat::Serializer) do
      klass = self

      schema do
        property :id, item.id
        properties do |attrs|
          attrs.name item.name
          attrs.age item.age
          attrs.controller_name context[:name]
        end
        link :self, url_for(item.id)
        entities :friends, item.friends, klass
      end

      def url_for(id)
        "http://foo.bar.com/#{id}"
      end
    end

    @serializer_class.adapter Oat::Adapters::HAL
  end

  let(:user_class) do
    Struct.new(:name, :age, :id, :friends)
  end

  let(:user2) { user_class.new('Joe', 33, 2, []) }
  let(:user1) { user_class.new('Ismael', 35, 1, [user2]) }

  describe '#to_hash' do
    it 'produces a HAL-compliant hash' do
      serializer = @serializer_class.new(user1, {name: 'some_controller'})
      serializer.to_hash.tap do |h|
        h[:id].should == user1.id
        h[:name].should == user1.name
        h[:age].should == user1.age
        h[:controller_name].should == 'some_controller'
        h[:_links][:self].should == "http://foo.bar.com/#{user1.id}"
        h[:_embedded][:friends].size.should == 1
        h[:_embedded][:friends][0].tap do |friend|
          friend[:id].should == user2.id
          friend[:name].should == user2.name
          friend[:age].should == user2.age
          friend[:controller_name].should == 'some_controller'
          friend[:_links][:self].should == "http://foo.bar.com/#{user2.id}"
        end
      end
    end
  end
end