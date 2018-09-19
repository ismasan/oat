RSpec.describe Oat do
  let(:f1) { double('Friend1', name: 'F1') }
  let(:f2) { double('Friend2', name: 'F2') }
  let(:account) { double('Account', id: 111) }
  let(:user) {
    double("Item",
      name: 'ismael',
      age: '40',
      friends: [f1, f2],
      account: account,
    )
  }

  it "has a version number" do
    expect(Oat::VERSION).not_to be nil
  end

  it "maps full HAL entities and sub-entities" do
    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name
        property :age, type: :integer
        entities :friends, from: :friends do |s|
          s.property :name
        end
      end
    end

    result = user_serializer.serialize(user)

    expect(result[:name]).to eq 'ismael'
    expect(result[:age]).to eq 40

    result[:_embedded][:friends].tap do |friends|
      expect(friends.size).to eq 2
      expect(friends.first[:name]).to eq 'F1'
    end
  end

  it "omits keys if :if option resolves to falsey" do
    allow(user).to receive(:shows_name?).and_return false
    allow(f1).to receive(:shows_name?).and_return false
    allow(f2).to receive(:shows_name?).and_return true

    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name, if: :shows_name?
        property :age, type: :integer
        entity :account do |s|
          s.property :id
        end
        entities :friends, from: :friends, if: :any? do |s|
          s.property :name, if: :shows_name?
        end
      end
    end

    result = user_serializer.serialize(user)

    expect(result.key?(:name)).to be false
    expect(result[:age]).to eq 40
    result[:_embedded][:friends].tap do |friends|
      expect(friends.first.key?(:name)).to be false
      expect(friends.last[:name]).to eq 'F2'
    end

    allow(user).to receive(:shows_name?).and_return true

    result = user_serializer.serialize(user)

    expect(result[:name]).to eq 'ismael'

    allow(user).to receive(:friends).and_return [] # #any? == false
    result = user_serializer.serialize(user)

    expect(result[:_embedded].key?(:friends)).to be false
  end

  it "maps sub-entities with named sub-serializer" do
    friend_serializer = Class.new(Oat::Serializer) do
      schema do
        property :friend_name, from: :name
      end
    end

    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name
        property :age, type: :integer
        entities :friends, with: friend_serializer
      end
    end

    result = user_serializer.serialize(user)

    expect(result[:name]).to eq 'ismael'
    expect(result[:age]).to eq 40

    result[:_embedded][:friends].tap do |friends|
      expect(friends.size).to eq 2
      expect(friends.first[:friend_name]).to eq 'F1'
    end
  end

  it "uses decorator methods and context object, if available" do
    context = {title: "Mr/Mrs."}

    base_serializer = Class.new(Oat::Serializer) do
      def with_title(name)
        "#{context[:title]} #{name}"
      end
    end

    friend_serializer = Class.new(base_serializer) do
      schema do
        property :friend_name, from: :name, decorate: :with_title
      end
    end

    user_serializer = Class.new(base_serializer) do
      schema do
        property :name, from: :name, decorate: :with_title
        property :age, type: :integer
        entities :friends, with: friend_serializer
      end
    end

    result = user_serializer.serialize(user, context: context)

    expect(result[:name]).to eq 'Mr/Mrs. ismael'
    expect(result[:age]).to eq 40

    result[:_embedded][:friends].tap do |friends|
      expect(friends.size).to eq 2
      expect(friends.first[:friend_name]).to eq 'Mr/Mrs. F1'
    end
  end

  it "uses custom class-level adapter" do
    example_adapter = Proc.new do |data|
      {
        props: data[:properties]
      }
    end

    user_serializer = Class.new(Oat::Serializer) do
      adapter example_adapter
      schema do
        property :name, from: :name
        property :age, type: :integer
      end
    end

    result = user_serializer.serialize(user)

    expect(result[:props][:name]).to eq 'ismael'
    expect(result[:props][:age]).to eq 40
  end

  it "uses custom run-time adapter" do
    example_adapter = Proc.new do |data|
      {
        props: data[:properties]
      }
    end

    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name
        property :age, type: :integer
      end
    end

    result = user_serializer.serialize(user, adapter: example_adapter)

    expect(result[:props][:name]).to eq 'ismael'
    expect(result[:props][:age]).to eq 40
  end

  it "maps full entities and sub-entities with custom adapter" do
    example_adapter = Proc.new do |data|
      data
    end

    user_serializer = Class.new(Oat::Serializer) do
      adapter example_adapter

      schema do
        property :name, from: :name
        property :age, type: :integer
        entity :account do |s|
          s.property :account_id, from: :id
        end

        entities :friends, from: :friends do |s|
          s.property :name
        end
      end
    end

    result = user_serializer.serialize(user)

    expect(result[:properties][:name]).to eq 'ismael'
    expect(result[:properties][:age]).to eq 40

    result[:entities][:friends].tap do |friends|
      expect(friends.size).to eq 2
      expect(friends.first[:properties][:name]).to eq 'F1'
    end
  end

  context "generating example outputs" do
    let(:user_serializer) do
      Class.new(Oat::Serializer) do
        schema do
          property :name, from: :name, example: 'Joan'
          property :age, type: :integer, example: 45
        end
      end
    end

    it "generates example" do
      result = user_serializer.example
      expect(result[:name]).to eq 'Joan'
      expect(result[:age]).to eq 45
    end

    it "generates example with custom run-time adapter" do
      example_adapter = Proc.new do |data|
        {
          props: data[:properties]
        }
      end

      result = user_serializer.example(adapter: example_adapter)
      expect(result[:props][:name]).to eq 'Joan'
      expect(result[:props][:age]).to eq 45
    end
  end

  it "raises useful exception if item doesn't respond to expected method" do
    user = double("Item",
      name: 'ismael',
    )

    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name
        property :age, type: :integer
      end
    end

    expect {
      user_serializer.serialize(user)
    }.to raise_error Oat::NoMethodError
  end
end
