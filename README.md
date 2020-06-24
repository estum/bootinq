# Rails Boot Inquirer (Bootinq)

The gem allows to select which bundle groups to boot in the current rails process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bootinq'
```

And then execute:

    $ bundle


## Get started

There are few steps to setup partial gem booting using Bootinq in any ruby application:

### 1. Declare loadable parts

The environment variable specifies which parts should be loaded using the assigned char keys. If the value is starts with `-`, all parts except the given will be loaded.

For example, looking at the configuration below, if we want to load only `api`, we should set `BOOTINQ=a`. If we want to load the all except `frontend` and `admin`, we should set `BOOTINQ=-fz`.

The name of the environment variable can be customized by changing the `env_key:`

```yaml
# config/bootinq.yml
env_key: BOOTINQ
default: "-f"

# Non-mountable parts
parts:
  c: :console

# Mountable parts (engines)
mount:
  a: :api
  f: :frontend
  z: :admin
```

### 2. Add gem groups

For each app part you should add a gem group named as `#{group_name}_boot`:

```ruby
# Gemfile

gem "api",      path: "apps/api",      group: :api_boot
gem "admin",    path: "apps/admin",    group: :admin_boot
gem "frontend", path: "apps/frontend", group: :frontend_boot

group :console_boot do
  gem 'term-ansicolor', '1.1.5'
  gem 'pry-rails'
end
```

## Ruby on Rails

### 3. Swap Bundle.require to Bootinq.require

Insert `require "bootinq"` to the top of `config/application.rb` file and replace `Bundler.require(*Rails.groups)` with the `Bootinq.require`:

#### Simple

```ruby
# config/application.rb

require File.expand_path('../boot', __FILE__)
require 'rails/all'
require 'bootinq'

# With no additional gem groups:
Bootinq.require(verbose: true)
# otherwise, set them like in <tt>Bundle.require(*Rails.groups(*groups))</tt>:
# Bootinq.require(:assets => %w(development test))

```

#### Separate load rails components with Bootinq

```ruby
# config/application.rb
require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

Bootinq.require do
  # Load the following components only when the frontend component is enabled
  on :frontend do
    require "sprockets/railtie"
    require "action_controller/railtie"
    require "action_view/railtie"
  end
end
```

### 4. Mount enabled engines in config/routes.rb

Use the `Bootinq.each_mountable {}` helper to easily mount currently loaded engines or do it by yourself checking `Bootinq.enabled?(engine_name)` :

```ruby
# config/routes.rb
Rails.application.routes.draw do
  Bootinq.each_mountable do |part|
    mount part.engine => '/', as: part.to_sym
  end

  root 'frontend/pages#index' if Bootinq.enabled?(:frontend)
end
```

### 5. Run app with only wanted parts

Now, you can set environment variable to tell workers which part of app it should load.

For example, with the [foreman](https://github.com/ddollar/foreman) in `Procfile`:

```
api:   env BOOTINQ=a MAX_THREADS=128 bundle exec puma -w 4
admin: env BOOTINQ=z bundle exec puma
```

## Usage with other frameworks

3. Locate `Bundler.require(...)` in your app and insert `require "bootinq"` above it.

4. Replace located `Bundler.require(...)` line with the `Bootinq.require(...)`.

For example, if you are using Grape:

```ruby
# config/application.rb

require 'boot'
require 'bootinq'

# Bundler.require :default, ENV['RACK_ENV']
Bootinq.require :default, ENV['RACK_ENV'], verbose: true


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/estum/bootinq.
