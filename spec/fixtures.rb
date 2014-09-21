module Fixtures

  def self.included(base)
    base.let(:user_class) { Struct.new(:name, :age, :id, :friends, :manager) }
    base.let(:friend) { user_class.new('Joe', 33, 2, []) }
    base.let(:manager) { user_class.new('Jane', 29, 3, []) }
    base.let(:user) { user_class.new('Ismael', 35, 1, [friend], manager) }

    base.let(:individual_serializer_class) do
      Class.new(Oat::Serializer) do
        klass = self
        schema do
          individual # set this entity as an individual resource
          type 'user' if respond_to?(:type)

          property :id, item.id
          map_properties :name, :age

          properties do |attrs|
            attrs.controller_name context[:name]
            attrs.message_from_above context[:message]
          end
        end
      end
    end

    base.let(:serializer_class) do
      Class.new(Oat::Serializer) do
        klass = self

        schema do
          type 'user' if respond_to?(:type)
          link :self, :href => url_for(item.id)
          link :empty, :href => nil

          meta :nation, 'zulu'

          property :id, item.id
          map_properties :name, :age
          properties do |attrs|
            attrs.controller_name context[:name]
            attrs.message_from_above context[:message]
          end

          entities :friends, item.friends, klass, :message => "Merged into parent's context"

          entity :manager, item.manager do |manager, s|
            s.type 'manager'
            s.link :self, :href => url_for(manager.id)
            s.properties do |attrs|
              attrs.id manager.id
              attrs.name manager.name
              attrs.age manager.age
            end
          end

          if adapter.respond_to?(:action)
            action :close_account do |action|
              action.href "http://foo.bar.com/#{item.id}/close_account"
              action.class 'danger'
              action.class 'irreversible'
              action.method 'DELETE'
              action.type   'application/json'
              action.field :current_password do |field|
                field.type :password
                field.title 'enter password:'
              end
            end
          end
        end

        def url_for(id)
          "http://foo.bar.com/#{id}"
        end
      end
    end
  end
end
