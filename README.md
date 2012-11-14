# Scholarsphere

Add to config/routes.rb
```
  mount Scholarsphere::Engine => '/'
```


Run the blacklight generator
```
rails generate blacklight --devise
```

Add include Scholarsphere::User into your user model
run the mailboxer generator

## Installation

Add this line to your application's Gemfile:

    gem '.'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install .

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
