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
