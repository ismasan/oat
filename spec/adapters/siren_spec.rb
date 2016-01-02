require 'spec_helper'
require 'oat/adapters/siren'

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

    context 'with multiple rels specified as an array for a single link' do
      let(:serializer_class) do
        Class.new(Oat::Serializer) do
          schema do
            type 'users'
            link ['describedby', 'http://rels.foo.bar.com/type'], :href => "http://foo.bar.com/meta/user"
          end
        end
      end

      it 'renders the rels as a Siren-compliant non-nested, flat  array' do
        expect(hash.fetch(:links)).to include(
          {:rel=>["describedby", "http://rels.foo.bar.com/type"], :href=>"http://foo.bar.com/meta/user"}
        )
      end
    end
  end
end
