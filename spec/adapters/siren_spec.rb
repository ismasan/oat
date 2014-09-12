require 'spec_helper'
require 'oat/adapters/siren'
require 'json'

describe Oat::Adapters::Siren do

  include Fixtures

  let(:serializer) { serializer_class.new(user, {:name => 'some_controller'}, Oat::Adapters::Siren) }
  let(:hash) { serializer.to_hash }

  describe '#to_hash' do
    it 'produces a Siren-compliant hash' do
      expect(hash.fetch(:class)).to match_array(['user'])

      expect(hash.fetch(:properties)).to include(
        :id => user.id,
        :name => user.name,
        :age => user.age,
        :controller_name => 'some_controller',
        :message_from_above => nil,
        # Meta property
        :nation => 'zulu'
      )

      expect(hash.fetch(:links).size).to be 2
      expect(hash.fetch(:links)).to include(
        { :rel => [:self], :href => "http://foo.bar.com/#{user.id}" },
        { :rel => [:empty], :href => nil }
      )

      expect(hash.fetch(:entities).size).to be 2

      # embedded friends
      embedded_friends = hash.fetch(:entities).select{ |o| o[:class].include? "user" }
      expect(embedded_friends.size).to be 1
      expect(embedded_friends.first.fetch(:properties)).to include(
        :id => friend.id,
        :name => friend.name,
        :age => friend.age,
        :controller_name => 'some_controller',
        :message_from_above => "Merged into parent's context"
      )
      expect(embedded_friends.first.fetch(:links).first).to include(
        :rel => [:self],
        :href => "http://foo.bar.com/#{friend.id}"
      )

      # sub-entity rel is an array, so it may have multiple values
      expect(embedded_friends.first.fetch(:rel)).to include(:friends)
      expect(embedded_friends.first.fetch(:rel)).to include('http://example.org/rels/person')

      embedded_managers = hash.fetch(:entities).select{ |o| o[:class].include? "manager" }
      expect(embedded_managers.size).to be 1
      expect(embedded_managers.first.fetch(:properties)).to include(
        :id => manager.id,
        :name => manager.name,
        :age => manager.age
      )
      expect(embedded_managers.first.fetch(:links).first).to include(
        :rel => [:self],
        :href => "http://foo.bar.com/#{manager.id}"
      )
      expect(embedded_managers.first.fetch(:rel)).to include(:manager)

      # action close_account
      actions = hash.fetch(:actions)
      expect(actions.size).to eql(1)
      expect(actions.first).to include(
        :name => :close_account,
        :href => "http://foo.bar.com/#{user.id}/close_account",
        :class => ['danger', 'irreversible'],
        :method => 'DELETE',
        :type => 'application/json'
      )

      expect(actions.first.fetch(:fields)).to include(
        :name => :current_password,
        :type => :password,
        :title => 'enter password:'
      )
    end

    context "when serializing properties" do
      let(:user_class) { Struct.new(:first_name, :last_name, :id) }
      let(:user) { user_class.new('Charlie', 'Brown', 1) }
      let(:serializer_class) do
        # abbreviated fixture for testing entity links
        Class.new(Oat::Serializer) do
          schema do
            map_properties :first_name, :last_name, :id
          end
        end
      end

      let(:serializer) { serializer_class.new(user, {:camelize_properties => camelize_properties}, Oat::Adapters::Siren) }
      let(:json_hash) { JSON.parse(JSON.dump(serializer.to_hash))  }
      # subject is the properties hash
      subject do
        json_hash['properties']
      end
      context "and property name camelization is not enabled" do
        let(:camelize_properties) { false }

        it 'should not camelize the property names' do
          expect(subject.keys).to include('first_name', 'last_name')
          expect(subject.keys).to_not include('firstName', 'lastName')
        end
      end

      context "and property name camelization is enabled" do
        let(:camelize_properties) { true }

        it 'should camelize the property names' do
          expect(subject.keys).to_not include('first_name', 'last_name')
          expect(subject.keys).to include('firstName', 'lastName')
        end
      end
    end

    context "when serializing optional attributes" do
      let(:serializer) { serializer_class.new(user, {:collapse_optional_attributes => collapse_attributes}, Oat::Adapters::Siren) }
      subject { JSON.parse(JSON.dump(serializer.to_hash))  }

      context "and collapsing is not enabled" do
        let(:collapse_attributes) { false }

        it "should serialize the empty attributes" do
          expect(subject['entities'].first['entities']).to_not be_nil
        end
      end

      context "and collapsing is enabled" do
        let(:collapse_attributes) { true }

        it "should not serialize empty attributes" do
          expect(subject['entities'].first['entities']).to be_nil
        end
      end
    end

    context 'when serializing sub-entities' do
      let(:serializer_class) do
        # abbreviated fixture for testing entity links
        Class.new(Oat::Serializer) do
          schema do
            entity :manager, item.manager, {:entity_link => context[:entity_link]} do |manager, s|
              s.type 'manager'
              s.link :self, :href => "http://example.com/#{manager.id}"
              s.property :id, manager.id
            end
          end
        end
      end

      let(:serializer) { serializer_class.new(user, {:entity_link => entity_link}, Oat::Adapters::Siren) }
      let(:json_hash) { JSON.parse(JSON.dump(serializer.to_hash))  }
      subject do
        # the entity being embedded is the subject
        json_hash["entities"].first
      end

      context 'with embedded representations' do
        let(:entity_link) { false }

        it 'should contain a properties hash' do
          expect(subject["properties"]).to_not be_nil
          expect(subject["properties"]["id"]).to eql(user.manager.id)
          # embedded representation DOES NOT contain an href attribute
          expect(subject["href"]).to be_nil
        end
      end

      context 'with embedded links' do
        let(:entity_link) { true }

        it 'should contain an href attribute' do
          # entity link must contain an href attribute
          expect(subject["href"]).to_not be_nil
        end
      end

    end

    context 'with a nil entity relationship' do
      let(:manager) { nil }

      it 'produces a Siren-compliant hash' do
        expect(hash.fetch(:class)).to match_array(['user'])

        expect(hash.fetch(:properties)).to include(
          :id => user.id,
          :name => user.name,
          :age => user.age,
          :controller_name => 'some_controller',
          :message_from_above => nil
        )

        expect(hash.fetch(:links).size).to be 2
        expect(hash.fetch(:links)).to include(
          { :rel => [:self], :href => "http://foo.bar.com/#{user.id}" },
          { :rel => [:empty], :href => nil }
        )

        expect(hash.fetch(:entities).size).to be 1

        # embedded friends
        embedded_friends = hash.fetch(:entities).select{ |o| o[:class].include? "user" }
        expect(embedded_friends.size).to be 1
        expect(embedded_friends.first.fetch(:properties)).to include(
          :id => friend.id,
          :name => friend.name,
          :age => friend.age,
          :controller_name => 'some_controller',
          :message_from_above => "Merged into parent's context"
        )
        expect(embedded_friends.first.fetch(:links).first).to include(
          :rel => [:self],
          :href => "http://foo.bar.com/#{friend.id}"
        )

        embedded_managers = hash.fetch(:entities).select{ |o| o[:class].include? "manager" }
        expect(embedded_managers.size).to be 0
      end
    end
  end
end
