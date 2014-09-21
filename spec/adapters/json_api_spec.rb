require 'spec_helper'
require 'oat/adapters/json_api'

describe Oat::Adapters::JsonAPI do

  include Fixtures

  let(:individual_serializer) { individual_serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::JsonAPI) }
  let(:serializer) { serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::JsonAPI) }
  let(:hash) { serializer.to_hash }
  let(:individual_hash) { individual_serializer.to_hash }

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
          :self => {
            :href => "http://foo.bar.com/#{user.id}"
          },
          # these links are added by embedding entities
          :manager => manager.id,
          :friends => [friend.id]
        )
      end
    end

    context 'individual top level' do
      subject(:individual_user){ individual_hash.fetch(:users) }

      it 'is not an array' do
        expect(individual_user).not_to be_kind_of(Array)
      end

      it 'contains the correct user properties' do
        expect(individual_user).to include(
          :id => user.id,
          :name => user.name,
          :age => user.age,
          :controller_name => 'some_controller',
          :message_from_above => nil
        )
      end
    end

    context 'meta' do
      subject(:meta) { hash.fetch(:meta) }

      it 'contains meta properties' do
        expect(meta[:nation]).to eq('zulu')
      end

      context 'without meta' do
        let(:serializer_class) {
           Class.new(Oat::Serializer) do
              schema do
                type 'users'
              end
            end
        }

        it 'does not contain meta information' do
          expect(hash[:meta]).to be_nil
        end
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
            :self => {
              :href => "http://foo.bar.com/#{friend.id}"
            }
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
            :links => { :self => { :href => "http://foo.bar.com/#{manager.id}"} }
          )
        end
      end

      context 'with nested entities' do
        let(:friend) { user_class.new('Joe', 33, 2, [other_friend]) }
        let(:other_friend) { user_class.new('Jack', 28, 4, []) }

        subject(:linked_friends){ hash.fetch(:linked).fetch(:friends) }
        its(:size) { should eq(2) }

        it 'has the correct entities' do
          expect(linked_friends.map{ |friend| friend.fetch(:id) }).to include(2, 4)
        end
      end
    end

    context 'object links' do
      context "as string" do
        let(:serializer_class) do
          Class.new(Oat::Serializer) do
            schema do
              type 'users'
              link :self, "45"
            end
          end
        end

        it 'renders just the string' do
          expect(hash.fetch(:users).first.fetch(:links)).to eq({
            :self => "45"
          })
        end
      end

      context 'as array' do
        let(:serializer_class) do
          Class.new(Oat::Serializer) do
            schema do
              type 'users'
              link :self, ["45", "46", "47"]
            end
          end
        end

        it 'renders the array' do
          expect(hash.fetch(:users).first.fetch(:links)).to eq({
            :self => ["45", "46", "47"]
          })
        end
      end

      context 'as hash' do
        context 'with single id' do
          let(:serializer_class) do
            Class.new(Oat::Serializer) do
              schema do
                type 'users'
                link :self, :href => "http://foo.bar.com/#{item.id}", :id => item.id.to_s, :type => 'user'
              end
            end
          end

          it 'renders all the keys' do
            expect(hash.fetch(:users).first.fetch(:links)).to eq({
              :self => {
                :href => "http://foo.bar.com/#{user.id}",
                :id => user.id.to_s,
                :type => 'user'
              }
            })
          end
        end

        context 'with ids' do
          let(:serializer_class) do
            Class.new(Oat::Serializer) do
              schema do
                type 'users'
                link :self, :href => "http://foo.bar.com/1,2,3", :ids => ["1", "2", "3"], :type => 'user'
              end
            end
          end

          it 'renders all the keys' do
            expect(hash.fetch(:users).first.fetch(:links)).to eq({
              :self => {
                :href => "http://foo.bar.com/1,2,3",
                :ids => ["1", "2", "3"],
                :type => 'user'
              }
            })
          end
        end

        context 'with id and ids' do
          let(:serializer_class) do
            Class.new(Oat::Serializer) do
              schema do
                type 'users'
                link :self, :id => "45", :ids => ["1", "2", "3"]
              end
            end
          end

          it "errs" do
            expect{hash}.to raise_error(ArgumentError)
          end
        end

        context 'with invalid keys' do
          let(:serializer_class) do
            Class.new(Oat::Serializer) do
              schema do
                type 'users'
                link :self, :not_a_valid_key => "value"
              end
            end
          end

          it "errs" do
            expect{hash}.to raise_error(ArgumentError)
          end
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
        expect(hash.fetch(:linked)).not_to include(:managers)
      end
    end

    context 'with a nil entities relationship' do
      let(:user) { user_class.new('Ismael', 35, 1, nil, manager) }
      let(:users) { hash.fetch(:users) }

      it 'excludes the entity from user links' do
        expect(users.first.fetch(:links)).not_to include(:friends)
      end

      it 'excludes the entity from the linked hash' do
        expect(hash.fetch(:linked)).not_to include(:friends)
      end
    end

    context 'when an empty entities relationship' do
      let(:user) { user_class.new('Ismael', 35, 1, [], manager) }
      let(:users) { hash.fetch(:users) }

      it 'excludes the entity from user links' do
        expect(users.first.fetch(:links)).not_to include(:friends)
      end

      it 'excludes the entity from the linked hash' do
        expect(hash.fetch(:linked)).not_to include(:friends)
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
            :self => {:href => "http://foo.bar.com/#{user.id}"},
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
              :links => { :self => {:href =>"http://foo.bar.com/#{manager.id}"} }
            )
          end
        end
      end
    end

    context 'link_template' do
      let(:serializer_class) do
        Class.new(Oat::Serializer) do
          schema do
            type 'users'
            link "user.managers", :href => "http://foo.bar.com/{user.id}/managers", :templated => true
            link "user.friends",  :href => "http://foo.bar.com/{user.id}/friends", :templated => true
          end
        end
      end

      it 'renders them top level' do
        expect(hash.fetch(:links)).to eq({
          "user.managers" => "http://foo.bar.com/{user.id}/managers",
          "user.friends"  => "http://foo.bar.com/{user.id}/friends"
        })
      end

      it "doesn't render them as links on the resource" do
        expect(hash.fetch(:users).first).to_not have_key(:links)
      end
    end
  end
end
