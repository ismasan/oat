# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oat/version'

Gem::Specification.new do |spec|
  spec.name          = "oat"
  spec.version       = Oat::VERSION
  spec.authors       = ["Ismael Celis"]
  spec.email         = ["ismaelct@gmail.com"]
  spec.description   = %q{Oat helps you separate your API schema definitions from the underlying media type. Media types can be plugged or swapped on demand globally or on the content-negotiation phase}
  spec.summary       = %q{Adapters-based serializers with Hypermedia support}
  spec.homepage      = "https://github.com/ismasan/oat"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "< 2.99"
end
