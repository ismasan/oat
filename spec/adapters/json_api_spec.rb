require 'spec_helper'
require 'oat/adapters/json_api'

describe Oat::Adapters::JsonAPI do

  include Fixtures

  let(:serializer) { serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::JsonAPI) }
  let(:hash) { serializer.to_hash }

  describe '#to_hash' do
    it 'produces a JSON-API compliant hash' do
      # the user being serialized
      users = hash.fetch(:users)
      expect(users.size).to be 1
      expect(users.first).to include(
        :id => user.id,
        :name => user.name,
        :age => user.age,
        :controller_name => 'some_controller',
        :message_from_above => nil
      )

      expect(users.first.fetch(:links)).to include(
        :self => "http://foo.bar.com/#{user.id}",
        # these links are added by embedding entities
        :manager => manager.id,
        :friends => [friend.id]
      )

      # embedded friends
      linked_friends = hash.fetch(:linked).fetch(:friends)
      expect(linked_friends.size).to be 1
      expect(linked_friends.first).to include(
        :id => friend.id,
        :name => friend.name,
        :age => friend.age,
        :controller_name => 'some_controller',
        :message_from_above => "Merged into parent's context"
      )

      expect(linked_friends.first.fetch(:links)).to include(
        :self => "http://foo.bar.com/#{friend.id}",
        :empty => nil,
        :friends => []
      )

      # embedded manager
      linked_managers = hash.fetch(:linked).fetch(:managers)
      expect(linked_managers.size).to be 1
      expect(linked_managers.first).to include(
        :id => manager.id,
        :name => manager.name,
        :age => manager.age,
        :links => { :self => "http://foo.bar.com/#{manager.id}" }
      )
    end

    context 'with a nil entity relationship' do
      let(:manager) { nil }

      it 'produces a JSON-API compliant hash' do
        # the user being serialized
        users = hash.fetch(:users)
        expect(users.size).to be 1
        expect(users.first).to include(
          :id => user.id,
          :name => user.name,
          :age => user.age,
          :controller_name => 'some_controller',
          :message_from_above => nil
        )

        expect(users.first.fetch(:links)).not_to include(:manager)
        expect(users.first.fetch(:links)).to include(
          :self => "http://foo.bar.com/#{user.id}",
          # these links are added by embedding entities
          :friends => [friend.id]
        )
        # embedded friends
        linked_friends = hash.fetch(:linked).fetch(:friends)
        expect(linked_friends.size).to be 1
        expect(linked_friends.first).to include(
          :id => friend.id,
          :name => friend.name,
          :age => friend.age,
          :controller_name => 'some_controller',
          :message_from_above => "Merged into parent's context"
        )

        expect(linked_friends.first.fetch(:links)).to include(
          :self => "http://foo.bar.com/#{friend.id}",
          :empty => nil,
          :friends => []
        )

        # embedded manager
        hash.fetch(:linked).fetch(:managers).should be_empty
      end
    end
  end
end
