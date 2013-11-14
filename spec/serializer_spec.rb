require 'spec_helper'

describe Oat::Serializer do

  before do
    @adapter_class = Class.new(Oat::Adapter) do
      def attributes(&block)
        data[:attributes].merge!(yield_props(&block))
      end

      def attribute(key, value)
        data[:attributes][key] = value
      end

      def link(rel, url)
        data[:links][rel] = url
      end
    end

    @serializer_class = Class.new(Oat::Serializer) do

      schema do
        attribute :id, item.id
        attributes do |attrs|
          attrs.name item.name
          attrs.age item.age
          attrs.controller_name context[:name]
        end
        link :self, url_for(item.id)
      end

      def url_for(id)
        "http://foo.bar.com/#{id}"
      end
    end

    @serializer_class.adapter @adapter_class
  end

  let(:user_class) do
    Struct.new(:name, :age, :id, :friends)
  end

  let(:user1) { user_class.new('Ismael', 35, 1, []) }

  it 'should have a version number' do
    Oat::VERSION.should_not be_nil
  end

  describe '#to_hash' do
    it 'builds Hash from item and context with attributes as defined in adapter' do
      serializer = @serializer_class.new(user1, name: 'some_controller')
      serializer.to_hash.tap do |h|
        h[:attributes][:id].should == user1.id
        h[:attributes][:name].should == user1.name
        h[:attributes][:age].should == user1.age
        h[:attributes][:controller_name].should == 'some_controller'
        h[:links][:self].should == "http://foo.bar.com/#{user1.id}"
      end
    end
  end

end
