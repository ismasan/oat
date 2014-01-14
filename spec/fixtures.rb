module Fixtures

  def self.included(base)
    base.let(:user_class) { Struct.new(:name, :age, :id, :friends, :manager) }
    base.let(:friend) { user_class.new('Joe', 33, 2, []) }
    base.let(:manager) { user_class.new('Jane', 29, 3, []) }
    base.let(:user) { user_class.new('Ismael', 35, 1, [friend], manager) }
    base.let(:serializer_class) do
      Class.new(Oat::Serializer) do
        klass = self

        schema do
          type 'user'
          link :self, href: url_for(item.id)

          property :id, item.id
          properties do |attrs|
            attrs.name item.name
            attrs.age item.age
            attrs.controller_name context[:name]
          end

          entities :friends, item.friends, klass

          entity :manager, item.manager do |manager, s|
            s.type 'manager'
            s.link :self, href: url_for(manager.id)
            s.properties do |attrs|
              attrs.id manager.id
              attrs.name manager.name
              attrs.age manager.age
            end
          end

          action :close_account do |action|
            action.href "http://foo.bar.com/#{item.id}/close_account"
            action.class 'danger'
            action.class 'irreversible'
            action.method 'DELETE'
            action.field :current_password do |field|
              field.type :password
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
