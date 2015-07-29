# Rails Boot Inquirer (Bootinq)

The gem allows to select which bundle groups to boot in the current rails process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bootinq'
```

And then execute:

    $ bundle

Insert `require "bootinq"` to the top of `config/application.rb` file.

Find a `Bundler.require(*Rails.groups)` line below and replace it with the `Bootinq.require`.

## Example `config/bootinq.yml`:

```yaml
env_key: BOOTINQ
default: "-f"

parts:
  s: :shared

mount:
  a: :api
  f: :engine
```

## Usage

Using example `bootinq.yml` above, you can create `api_boot` group in your `Gemfile` and load gems from that only when flag `BOOTINQ=a` is set. The group can contain local `api` gem, which provides a mountable engine. Please, see `specs/dummy` for the example.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/estum/bootinq.

