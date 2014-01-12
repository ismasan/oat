require 'spec_helper'
require 'oat/adapters/siren'

describe Oat::Adapters::Siren do

  include Fixtures

  subject{ serializer_class.new(user, {name: 'some_controller'}, Oat::Adapters::Siren) }

  describe '#to_hash' do
    it 'produces a Siren-compliant hash' do
      subject.to_hash.tap do |h|
        #siren class
        h[:class].should == ['user']
        # properties
        h[:properties][:id].should == user.id
        h[:properties][:name].should == user.name
        h[:properties][:age].should == user.age
        h[:properties][:controller_name].should == 'some_controller'
        # links
        h[:links][0][:rel].should == [:self]
        h[:links][0][:href].should == "http://foo.bar.com/#{user.id}"
        # embedded manager
        h[:entities][1].tap do |m|
          m[:class].should == ['manager']
          m[:properties][:id].should == manager.id
          m[:properties][:name].should == manager.name
          m[:properties][:age].should  == manager.age
          m[:links][0][:rel].should == [:self]
          m[:links][0][:href].should == "http://foo.bar.com/#{manager.id}"
        end
        # embedded friends
        h[:entities][0].tap do |f|
          f[:class].should == ['user']
          f[:properties][:id].should == friend.id
          f[:properties][:name].should == friend.name
          f[:properties][:age].should == friend.age
          f[:properties][:controller_name].should == 'some_controller'
          f[:links][0][:rel].should == [:self]
          f[:links][0][:href].should == "http://foo.bar.com/#{friend.id}"
        end
        # action close_account
        h[:actions][0].tap do |a|
          a[:name].should == :close_account
          a[:href].should == "http://foo.bar.com/#{user.id}/close_account"
          a[:class].should == ['danger', 'irreversible']
          a[:method].should == 'DELETE'
          a[:fields][0].tap do |f|
            f[:name].should == :current_password
            f[:type].should == :password
          end
        end
      end
    end
  end
end