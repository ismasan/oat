require 'spec_helper'
require 'oat/adapters/json_api'

describe Oat::Adapters::JsonAPI do

  include Fixtures

  let(:serializer) { serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::JsonAPI) }
  let(:hash) { serializer.to_hash }

  describe '#to_hash' do
    context 'top level' do
      subject(:users){ hash.fetch(:users) }
      its(:size) { should eq(1) }

      it 'contains the correct user properties' do
        expect(users.first).to include(
          :id => user.id,
          :name => user.name,
          :age => user.age,
          :controller_name => 'some_controller',
          :message_from_above => nil
        )
      end

      it 'contains the correct user links' do
        expect(users.first.fetch(:links)).to include(
          :self => "http://foo.bar.com/#{user.id}",
          # these links are added by embedding entities
          :manager => manager.id,
          :friends => [friend.id]
        )
      end
    end

    context 'linked' do
      context 'using #entities' do
        subject(:linked_friends){ hash.fetch(:linked).fetch(:friends) }

        its(:size) { should eq(1) }

        it 'contains the correct properties' do
          expect(linked_friends.first).to include(
            :id => friend.id,
            :name => friend.name,
            :age => friend.age,
            :controller_name => 'some_controller',
            :message_from_above => "Merged into parent's context"
          )
        end

        it 'contains the correct links' do
          expect(linked_friends.first.fetch(:links)).to include(
            :self => "http://foo.bar.com/#{friend.id}",
            :empty => nil,
            :friends => []
          )
        end
      end

      context 'using #entity' do
        subject(:linked_managers){ hash.fetch(:linked).fetch(:managers) }
        its(:size) { should eq(1) }

        it "contains the correct properties and links" do
          expect(linked_managers.first).to include(
            :id => manager.id,
            :name => manager.name,
            :age => manager.age,
            :links => { :self => "http://foo.bar.com/#{manager.id}" }
          )
        end
      end
    end

    context 'with a nil entity relationship' do
      let(:manager) { nil }
      let(:users) { hash.fetch(:users) }

      it 'excludes the entity from user links' do
        expect(users.first.fetch(:links)).not_to include(:manager)
      end

      it 'excludes the entity from the linked hash' do
        hash.fetch(:linked).fetch(:managers).should be_empty
      end
    end
  end
end
