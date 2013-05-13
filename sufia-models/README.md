# Sufia::Models

An ongoing project to extract Sufia models.

## Why

Sufia is a Rails engine that is an opinionated -- in a good way -- self-deposit application built from [Project Hydra components](https://github.com/projecthydra) that is mostly "turn-key ready".
And while the turn-key solution is greatly appreciated, there are use cases, namely ours, where its opinions don't quite work;
Namely the views and controllers. We want a different work flow through our application and a notably different UI.

Enter the **sufia-models** gem.
The goal of **sufia-models** is to provide a common foundation for the Sufia engine as well as a common foundation for other engines -- [Curate](https://github.com/ndlib/curate).

## Installation

Add this line to your application's Gemfile:

    gem 'sufia-models'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sufia-models

## Usage

This project is closely tied to [Sufia](https://github.com/projecthydra/sufia).
Presently this gems tests are found in the sufia gem (I'm working on it).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
