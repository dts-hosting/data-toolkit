source "https://rubygems.org"

# rails gems
gem "rails", "~> 8.0.1"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "thruster", require: false

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv"
  gem "hotwire-spark"
  gem "standard"
  gem "standard-rails"
end

group :development do
  gem "htmlbeautifier"
  gem "kamal", "~> 2.7"
  gem "letter_opener"
  gem "overcommit", require: false
  gem "solargraph"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "mocha"
  gem "selenium-webdriver"
  gem "webmock"
end

# app gems
gem "collectionspace-client",
  github: "collectionspace/collectionspace-client",
  branch: "main"
gem "collectionspace-mapper",
  github: "collectionspace/collectionspace-mapper",
  branch: "data-toolkit"
# I feel like I shouldn't have to put this here, as data-toolkit never
#   calls or uses collectionspace-refcache directly.
# If I don't put this here, and include the data-toolkit branch of
#   collectionspace-refcache only in collectionspace-mapper Gemfile,
#   then data-toolkit doesn't see refcache as a dependency at all and it
#   falls over starting up when mapper is autoloaded and requires refcache:
#     /Users/kristina/.rbenv/versions/3.4.1/lib/ruby/3.4.0/bundled_gems.rb:82:
#     in 'Kernel.require': cannot load such file -- collectionspace/refcache (LoadError)
# If I add refcache as a dependency in mapper's gemspec, data-toolkit
#   installs the latest release of refcache, which does not work with changes
#   made in mapper.
# Hopefully this is here temporarily until we are not having to point to
#   branches, and development isn't so intense
gem "collectionspace-refcache",
  github: "collectionspace/collectionspace-refcache",
  branch: "data-toolkit"
gem "csv"
gem "csvlint",
  git: "https://github.com/lyrasis/csvlint.rb.git",
  tag: "1.5.0"
gem "local_time"
gem "mission_control-jobs"
gem "pagy"
gem "scout_apm"
