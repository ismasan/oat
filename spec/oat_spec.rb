RSpec.describe Oat do
  let(:f1) { double(name: 'F1') }
  let(:f2) { double(name: 'F2') }
  let(:user) {
    double("Item",
      name: 'ismael',
      age: '40',
      friends: [f1, f2]
    )
  }

  it "has a version number" do
    expect(Oat::VERSION).not_to be nil
  end

  it "maps simple HAL properties" do
    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name
        property :age, type: :integer
      end
    end

    result = user_serializer.serialize(user)

    expect(result[:name]).to eq 'ismael'
    expect(result[:age]).to eq 40
  end

  it "generates example" do
    user_serializer = Class.new(Oat::Serializer) do
      schema do
        property :name, from: :name, example: 'Joan'
        property :age, type: :integer, example: 45
      end
    end

    result = user_serializer.example
    expect(result[:name]).to eq 'Joan'
    expect(result[:age]).to eq 45
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
