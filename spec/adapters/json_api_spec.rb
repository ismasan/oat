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

      context 'with nested entities' do
        let(:friend) { user_class.new('Joe', 33, 2, [other_friend]) }
        let(:other_friend) { user_class.new('Jack', 28, 4, []) }

        subject(:linked_friends){ hash.fetch(:linked).fetch(:friends) }
        its(:size) { should eq(2) }

        it 'has the correct entities' do
          linked_friends.map{ |friend| friend.fetch(:id) }.should include(2, 4)
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

    context 'with an entity collection' do
      let(:serializer_collection_class) do
        USER_SERIALIZER = serializer_class unless defined?(USER_SERIALIZER)
        Class.new(Oat::Serializer) do
          schema do
            type 'users'
            collection :users, item, USER_SERIALIZER
          end
        end
      end

      let(:collection_serializer){
        serializer_collection_class.new(
          [user,friend],
          {:name => "some_controller"},
          Oat::Adapters::JsonAPI
        )
      }
      let(:collection_hash) { collection_serializer.to_hash }

      context 'top level' do
        subject(:users){ collection_hash.fetch(:users) }
        its(:size) { should eq(2) }

        it 'contains the correct first user properties' do
          expect(users[0]).to include(
            :id => user.id,
            :name => user.name,
            :age => user.age,
            :controller_name => 'some_controller',
            :message_from_above => nil
          )
        end

        it 'contains the correct second user properties' do
          expect(users[1]).to include(
            :id => friend.id,
            :name => friend.name,
            :age => friend.age,
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

        context 'sub entity' do
          subject(:linked_managers){ collection_hash.fetch(:linked).fetch(:managers) }
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

    end
  end
end
