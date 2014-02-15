require 'spec_helper'
require 'oat/adapters/hal'

describe Oat::Adapters::HAL do

  include Fixtures

  let(:serializer) { serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::HAL) }
  let(:hash) { serializer.to_hash }

  describe '#to_hash' do
    it 'produces a HAL-compliant hash' do
      expect(hash).to include(
        # properties
        :id => user.id,
        :name => user.name,
        :age => user.age,
        :controller_name => 'some_controller',
        :message_from_above => nil
      )

      # links
      expect(hash.fetch(:_links)).to include(:self => { :href => "http://foo.bar.com/#{user.id}" })

      # HAL Spec says href is REQUIRED
      expect(hash.fetch(:_links)).not_to include(:empty)
      expect(hash.fetch(:_embedded)).to include(:manager, :friends)

      # embedded manager
      expect(hash.fetch(:_embedded).fetch(:manager)).to include(
        :id => manager.id,
        :name => manager.name,
        :age => manager.age,
        :_links => { :self => { :href => "http://foo.bar.com/#{manager.id}" } }
      )

      # embedded friends
      expect(hash.fetch(:_embedded).fetch(:friends).size).to be 1
      expect(hash.fetch(:_embedded).fetch(:friends).first).to include(
        :id => friend.id,
        :name => friend.name,
        :age => friend.age,
        :controller_name => 'some_controller',
        :message_from_above => "Merged into parent's context",
        :_links => { :self => { :href => "http://foo.bar.com/#{friend.id}" } }
      )
    end

    context 'with a nil entity relationship' do
      let(:manager) { nil }

      it 'produces a HAL-compliant hash' do
        # properties
        expect(hash).to include(
          :id => user.id,
          :name => user.name,
          :age => user.age,
          :controller_name => 'some_controller',
          :message_from_above => nil
        )

        expect(hash.fetch(:_links)).to include(:self => { :href => "http://foo.bar.com/#{user.id}" })

        # HAL Spec says href is REQUIRED
        expect(hash.fetch(:_links)).not_to include(:empty)
        expect(hash.fetch(:_embedded)).to include(:manager, :friends)

        expect(hash.fetch(:_embedded).fetch(:manager)).to be_nil

        # embedded friends
        expect(hash.fetch(:_embedded).fetch(:friends).size).to be 1
        expect(hash.fetch(:_embedded).fetch(:friends).first).to include(
          :id => friend.id,
          :name => friend.name,
          :age => friend.age,
          :controller_name => 'some_controller',
          :message_from_above => "Merged into parent's context",
          :_links => { :self => { :href => "http://foo.bar.com/#{friend.id}" } }
        )
      end
    end
  end
end
