source 'https://rubygems.org'

# Declare your gem's dependencies in bootinq.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

gem 'rails', '>= 5.0'
gem 'sqlite3'

# To use a debugger
gem 'byebug', group: [:development, :test]

group :development, :test do
  # You need these
  gem "rspec"
  gem "rspec-rails"
  gem "pry"
end

group :development do
  # You don't need these, but I use them
  gem "awesome_print"
  gem "commonmarker", require: false
  gem "yard"
end

group :shared_boot do
  gem 'shared', path: 'spec/dummy/engines/shared'
end

group :api_part_boot do
  gem 'api_part', path: 'spec/dummy/engines/api_part'
end

group :api_boot do
  gem 'api', path: 'spec/dummy/engines/api'
end

group :api2_boot do
  gem 'api2', path: 'spec/dummy/engines/api2'
end