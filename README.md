# Oat [![Build Status](https://travis-ci.org/ismasan/oat.png)](https://travis-ci.org/ismasan/oat)

Adapters-based API serializers with Hypermedia support for Ruby apps. Read [the blog post](http://new-bamboo.co.uk/blog/2013/11/21/oat-explicit-media-type-serializers-in-ruby) for context and motivation.

## What

Oat lets you design your API payloads succinctly while conforming to your *media type* of choice (hypermedia or not).
The details of the media type are dealt with by pluggable adapters.

Oat ships with adapters for HAL, Siren and JsonAPI, and it's easy to write your own.

## Serializers

A serializer describes one or more of your API's *entities*.

You extend from [Oat::Serializer](https://github.com/ismasan/oat/blob/master/lib/oat/serializer.rb) to define your own serializers.

```ruby
require 'oat/adapters/hal'
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    type "product"
    link :self, href: product_url(item)

    properties do |props|
      props.title item.title
      props.price item.price
      props.description item.blurb
    end
  end

end
```

Then in your app (for example a Rails controller)

```ruby
product = Product.find(params[:id])
render json: ProductSerializer.new(product)
```

Serializers require a single object as argument, which can be a model instance, a presenter or any other domain object.

The full serializer signature is `item`, `context`, `adapter_class`.

* `item` a model or presenter instance. It is available in your serializer's schema as `item`.
* `context` (optional) a context hash that is passed to the serializer and sub-serializers as the `context` variable. Useful if you need to pass request-specific data.
* `adapter_class` (optional) A serializer's adapter can be configured at class-level or passed here to the initializer. Useful if you want to switch adapters based on request data. More on this below.

### Defining Properties

There are a few different ways of defining properties on a serializer.

Properties can be added explicitly using `property`. In this case, you can map an arbitrary value to an arbitrary key:

```ruby
require 'oat/adapters/hal'
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    type "product"
    link :self, href: product_url(item)

    property :title, item.title
    property :price, item.price
    property :description, item.blurb
    property :the_number_one, 1
  end
end
```

Similarly, properties can be added within a block using `properties` to be more concise or make the code more readable. Again, these will set arbitrary values for arbitrary keys:

```ruby
require 'oat/adapters/hal'
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    type "product"
    link :self, href: product_url(item)

    properties do |p|
      p.title           item.title
      p.price           item.price
      p.description     item.blurb
      p.the_number_one  1
    end
  end
end
```

In many cases, you will want to simply map the properties of `item` to a property in the serializer. This can be easily done using `map_properties`. This method takes a list of method or attribute names to which `item` will respond. Note that you cannot assign arbitrary values and keys using `map_properties` - the serializer will simply add a key and call that method on `item` to assign the value.

```ruby
require 'oat/adapters/hal'
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    type "product"
    link :self, href: product_url(item)

    map_properties :title, :price
    property :description, item.blurb
    property :the_number_one, 1
  end
end
```

## Adapters

Using the included [HAL](http://stateless.co/hal_specification.html) adapter, the `ProductSerializer` above would render the following JSON:

```json
{
    "_links": {
        "self": {"href": "http://example.com/products/1"}
    },
    "title": "Some product",
    "price": 1000,
    "description": "..."
}
```

You can easily swap adapters. The same `ProductSerializer`, this time using the [Siren](https://github.com/kevinswiber/siren) adapter:

```ruby
adapter Oat::Adapters::Siren
```

... Renders this JSON:

```json
{
    "class": ["product"],
    "links": [
        { "rel": [ "self" ], "href": "http://example.com/products/1" }
    ],
    "properties": {
        "title": "Some product",
        "price": 1000,
        "description": "..."
    }
}
```
At the moment Oat ships with adapters for [HAL](http://stateless.co/hal_specification.html), [Siren](https://github.com/kevinswiber/siren) and [JsonAPI](http://jsonapi.org/), but it's easy to write your own.

Note: Oat adapters are not *required* by default. Your code should explicitely require the ones it needs:

```ruby
# HAL
require 'oat/adapters/hal'
# Siren
require 'oat/adapters/siren'
# JsonAPI
require 'oat/adapters/json_api'
```

## Switching adapters dynamically

Adapters can also be passed as an argument to serializer instances.

```ruby
ProductSerializer.new(product, nil, Oat::Adapters::HAL)
```

That means that your app could switch adapters on run time depending, for example, on the request's `Accept` header or anything you need.

Note: a different library could be written to make adapter-switching auto-magical for different frameworks, for example using [Responders](http://api.rubyonrails.org/classes/ActionController/Responder.html) in Rails.

## Nested serializers

It's common for a media type to include "embedded" entities within a payload. For example an `account` entity may have many `users`. An Oat serializer can inline such relationships:

```ruby
class AccountSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    property :id, item.id
    property :status, item.status
    # user entities
    entities :users, item.users do |user, user_serializer|
      user_serializer.name user.name
      user_serializer.email user.email
    end
  end
end
```

Another, more reusable option is to use a nested serializer. Instead of a block, you pass another serializer class that will handle serializing `user` entities.

```ruby
class AccountSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    property :id, item.id
    property :status, item.status
    # user entities
    entities :users, item.users, UserSerializer
  end
end
```

And the `UserSerializer` may look like this:

```ruby
class UserSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    property :name, item.name
    property :email, item.name
  end
end
```

In the user serializer, `item` refers to the user instance being wrapped by the serializer.

The bundled hypermedia adapters ship with an `entities` method to add arrays of entities, and an `entity` method to add a single entity.

```ruby
# single entity
entity :child, item.child do |child, s|
  s.name child.name
  s.id child.id
end

# list of entities
entities :children, item.children do |child, s|
  s.name child.name
  s.id child.id
end
```

Both can be expressed using a separate serializer:

```ruby
# single entity
entity :child, item.child, ChildSerializer

# list of entities
entities :children, item.children, ChildSerializer
```

The way sub-entities are rendered in the final payload is up to the adapter. In HAL the example above would be:

```json
{
  ...,
  "_embedded": {
    "child": {"name": "child's name", "id": 1},
    "children": [
      {"name": "child 2 name", "id": 2},
      {"name": "child 3 name", "id": 3},
      ...
    ]
  }
}
```

## Subclassing

Serializers can be subclassed, for example if you want all your serializers to share the same adapter or add shared helper methods.

```ruby
class MyAppSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  protected

  def format_price(price)
    Money.new(price, 'GBP').format
  end
end
```

```ruby
class ProductSerializer < MyAppSerializer
  schema do
    property :title, item.title
    property :price, format_price(item.price)
  end
end
```

This is useful if you want your serializers to better express your app's domain. For example, a serializer for a social app:

```ruby
class UserSerializer < SocialSerializer
  schema do
    name item.name
    email item.email
    # friend entities
    friends item.friends
  end
end
```

The superclass defines the methods `name`, `email` and `friends`, which in turn delegate to the adapter's setters.

```ruby
class SocialSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL # or whatever

  # friendly setters
  protected

  def name(value)
    property :name, value
  end

  def email(value)
    property :email, value
  end

  def friends(objects)
    entities :friends, objects, FriendSerializer
  end
end
```

## URLs

Hypermedia is all about the URLs linking your resources together. Oat adapters can have methods to declare links in your entity schema but it's up to your code/framework how to create those links.
A simple stand-alone implementation could be:

```ruby
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    link :self, href: product_url(item.id)
    ...
  end

  protected

  # helper URL method
  def product_url(id)
    "https://api.com/products/#{id}"
  end
end
```

In frameworks like Rails, you'll probably want to use the URL helpers created by the `routes.rb` file. Two options:

### Pass a context hash to serializers

You can pass a context hash as second argument to serializers. This object will be passed to nested serializers too. For example, you can pass the controller instance itself.

```ruby
# users_controller.rb

def show
  user = User.find(params[:id])
  render json: UserSerializer.new(user, controller: self)
end
```

Then, in the `UserSerializer`:
```ruby
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    # `context` is the controller, which responds to URL helpers.
    link :self, href: context[:controller].product_url(item)
    ...
  end
end
```

### Mixin Rails' routing module

Alternatively, you can mix in Rails routing helpers directly into your serializers.

```ruby
class MyAppParentSerializer < Oat::Serializer
  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers
  def self.default_url_options
    Rails.application.routes.default_url_options
  end

  adapter Oat::Adapters::HAL
end
```

Then your serializer sub-classes can just use the URL helpers

```ruby
class ProductSerializer < MyAppParentSerializer
  schema do
    # `product_url` is mixed in from Rails' routing system.
    link :self, href: product_url(item)
    ...
  end
end
```

However, since serializers don't have access to the current request, for this to work you must configure each environment's base host. In `config/environments/production.rb`:

```ruby
config.after_initialize do
  Rails.application.routes.default_url_options[:host] = 'api.com'
end
```

NOTE: Rails URL helpers could be handled by a separate oat-rails gem.

## Custom adapters.

An adapter's primary concern is to abstract away the details of specific media types.

Methods defined in an adapter are exposed as `schema` setters in your serializers.
Ideally different adapters should expose the same methods so your serializers can switch adapters without loosing compatibility. For example all bundled adapters expose the following methods:

* `type` The type of the entity. Renders as "class" in Siren, root node name in JsonAPI, not used in HAL.
* `link` Add a link with `rel` and `href`. Renders inside "_links" in HAL, "links" in Siren and JsonAP.
* `property` Add a property to the entity. Top level attributes in HAL and JsonAPI, "properties" node in Siren.
* `properties` Yield a properties object to set many properties at once.
* `entity` Add a single sub-entity. "_embedded" node in HAL, "entities" in Siren, "linked" in JsonAPI.
* `entities` Add a collection of sub-entities.

You can define these in your own custom adapters if you're using your own media type or need to implement a different spec.

```ruby
class CustomAdapter < Oat::Adapter

  def type(*types)
    data[:rel] = types
  end

  def property(name, value)
    data[:attr][name] = value
  end

  def entity(name, obj, serializer_class = nil, &block)
    data[:nested_documents] = serializer_from_block_or_class(obj, serializer_class, &block)
  end

  ... etc
end
```

An adapter class provides a `data` object (just a Hash) that stores your data in the structure you want. An adapter's public methods are exposed to your serializers.

## Unconventional or domain specific adapters

Although adapters should in general comply with a common interface, you can still create your own domain-specific adapters if you need to.

Let's say you're working on a media-type specification specializing in describing social networks and want your payload definitions to express the concept of "friendship". You want your serializers to look like:

```ruby
class UserSerializer < Oat::Serializer
  adapter SocialAdapter

  schema do
    name item.name
    email item.email

    # Friend entity
    friends item.friends do |friend, friend_serializer|
      friend_serializer.name friend.name
      friend_serializer.email friend.email
    end
  end
end
```

A custom media type could return JSON looking looking like this:

```json
{
    "name": "Joe",
    "email": "joe@email.com",
    "friends": [
        {"name": "Jane", "email":"jane@email.com"},
        ...
    ]
}
```

The adapter for that would be:

```ruby
class SocialAdapter < Oat::Adapter

  def name(value)
    data[:name] = value
  end

  def email(value)
    data[:email] = value
  end

  def friends(friend_list, serializer_class = nil, &block)
    data[:friends] = friend_list.map do |obj|
      serializer_from_block_or_class(obj, serializer_class, &block)
    end
  end
end
```

But you can easily write an adapter that turns your domain-specific serializers into HAL-compliant JSON.

```ruby
class SocialHalAdapter < Oat::Adapters::HAL

  def name(value)
    property :name, value
  end

  def email(value)
    property :email, value
  end

  def friends(friend_list, serializer_class = nil, &block)
    entities :friends, friend_list, serializer_class, &block
  end
end
```

The result for the SocialHalAdapter is:

```json
{
    "name": "Joe",
    "email": "joe@email.com",
    "_embedded": {
        "friends": [
            {"name": "Jane", "email":"jane@email.com"},
            ...
        ]
    }
}
```

You can take a look at [the built-in Hypermedia adapters](https://github.com/ismasan/oat/tree/master/lib/oat/adapters) for guidance.

## Installation

Add this line to your application's Gemfile:

    gem 'oat'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oat

## TODO / contributions welcome

* JsonAPI URL and ID modes, top-level links
* testing module that can be used for testing spec-compliance in user apps?

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

Many thanks to all contributors! https://github.com/ismasan/oat/graphs/contributors
