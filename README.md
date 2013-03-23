# ActAsImportable

Helps you easily import records from a CSV file or an array of hashes.

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

User.import_csv_file('/path/to/file.csv')
# or
User.import_csv_text(csv_text)
# or
User.import_data(array_of_hashes)
```

## CSV File Format

The importer will automatically map the column headers to the attributes of the model.

###Example:
```
first_name,last_name,email
John,Smith,j.smith@gmail.com
```

This will create a new User called John Smith with the email address j.smith@gmail.com.

## Updating existing records

You can specify a unique field that will be used to find existing records.

###Example:
```
User.import_csv_file('/path/to/file.csv', :uid => :email)
```

This will find an existing record with a matching email address and update their name.
If no record exists it will create a new one.


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
