require 'spec_helper'
require 'oat/adapters/hal'

describe Oat::Adapters::HAL do

  before do
    @serializer_class = Class.new(Oat::Serializer) do
      klass = self

      schema do
        link :self, href: url_for(item.id)

        property :id, item.id
        properties do |attrs|
          attrs.name item.name
          attrs.age item.age
          attrs.controller_name context[:name]
        end

        entities :friends, item.friends, klass

        entity :manager, item.manager do |manager, s|
          s.link :self, href: url_for(manager.id)
          s.properties do |attrs|
            attrs.name manager.name
            attrs.age manager.age
          end
        end if item.manager
      end

      def url_for(id)
        "http://foo.bar.com/#{id}"
      end
    end

    @serializer_class.adapter Oat::Adapters::HAL
  end

  let(:user_class) do
    Struct.new(:name, :age, :id, :friends, :manager)
  end

  let(:friend) { user_class.new('Joe', 33, 2, []) }
  let(:manager) { user_class.new('Jane', 29, 3, []) }
  let(:user) { user_class.new('Ismael', 35, 1, [friend], manager) }

  describe '#to_hash' do
    it 'produces a HAL-compliant hash' do
      serializer = @serializer_class.new(user, {name: 'some_controller'})
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