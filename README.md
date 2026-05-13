# three.rb
Ruby 3D Library.

## Status

This project is in the initial implementation phase. The current focus is the Ruby gem foundation and the first math/core APIs.

## Quick Start

```ruby
require "three"

vector = Three::Vector3.new(1, 2, 2)
puts vector.length # 3.0
```

## Development

Install dependencies:

```sh
bundle install
```

Run tests:

```sh
bundle exec rake test
```

## Documents

- [Implementation Plan](docs/implementation-plan.md)
