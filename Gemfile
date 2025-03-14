source "https://rubygems.org"

# rails gems
gem "rails", "~> 8.0.2"
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
  gem "kamal", "~> 2.5"
  gem "letter_opener"
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
gem "collectionspace-client", github: "collectionspace/collectionspace-client", branch: "main"
gem "pagy"
