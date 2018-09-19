RSpec.describe Oat do
  it "has a version number" do
    expect(Oat::VERSION).not_to be nil
  end

  it "works" do
    f1 = double(name: 'F1')
    f2 = double(name: 'F2')

    user = double("Item",
      name: 'ismael',
      age: '40',
      friends: [f1, f2]
    )


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
end
