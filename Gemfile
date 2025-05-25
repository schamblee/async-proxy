source "https://rubygems.org"

ruby "3.4.4"

# Rails 8
gem "rails", "~> 8.0.0"

# Use Puma as the app server
gem "puma", ">= 6.0"

# Async handling gems
gem "concurrent-ruby", "~> 1.3"
gem "httparty", "~> 0.22"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database for Active Record
# gem "sqlite3", "~> 2.0" # We're skipping Active Record

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
end

group :test do
  gem "minitest", "~> 5.16"
  gem "minitest-reporters", "~> 1.5"
  gem "webmock", "~> 3.14"
  gem "rack-test", "~> 2.0"
end
