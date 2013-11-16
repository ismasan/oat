# Oat [![Build Status](https://travis-ci.org/ismasan/oat.png)](https://travis-ci.org/ismasan/oat)

Adapters-based API serializers with Hypermedia support for Ruby apps.

## What

Oat lets you design your API payloads succintingly while conforming to your *media type* of choice (hypermedia or not). 
The details of the media type are dealt with by pluggable adapters.

Oat ships with adapters for HAL, Siren and JsonAPI, and it's easy to write your own.

## Serializers

A serializer describes one or more of your API's *entities*.

You extend from [Oat::Serializer](https://github.com/ismasan/oat/blob/master/lib/oat/serializer.rb) to define your own serializers.

```ruby
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
* `context` (optional) a context object or hash that is passed to the serializer and sub-serializers as the `context` variable. Useful if you need to pass request-specific data.
* `adapter_class` (optional) A serializer's adapter can be configured at class-level or passed here to the initializer. Useful if you want to switch adapters based on request data. More on this below.

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

I the user serializer, `item` refers to the user instance being wrapped by the serializer.

## Sub-classing

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

## Custom adapters.

Adapters let you simplify your API payload design by making it more domain specific.

An adapter class provides a `data` object (just a Hash) that stores your data in the structure you want. An adapter's public methods are exposed to your serializers.

Let's say you're building a social API and want your payload definitions to express the concept of "friendship". You want your serializers to look like:

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

## Switching adapters dinamically

Adapters can also be passed as an argument to serializer instances.

```ruby
ProductSerializer.new(product, nil, Oat::Adapters::HAL)
```

That means that your app could switch adapters on run time depending, for example, on the request's `Accept` header or anything you need.

Not: a different library could be written to make adapter-switching auto-magical for different frameworks, for example using [Responders](http://api.rubyonrails.org/classes/ActionController/Responder.html) in Rails.

## Installation

Add this line to your application's Gemfile:

    gem 'oat'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oat

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
