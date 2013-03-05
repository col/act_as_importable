# ActAsImportable

Help you easily import models from a CSV file.

## Installation

Add this line to your application's Gemfile:

    gem 'act_as_importable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install act_as_importable

## Usage

```ruby
class User < ActiveRecord::Base
  act_as_importable
end
```

## Test

```shell
rake
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
