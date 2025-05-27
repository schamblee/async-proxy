# spec/spec_helper.rb
ENV["RACK_ENV"] = "test"

require "rack/test"
require "rspec"
require_relative "../config/environment"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  # Pretty print test output
  config.formatter = :documentation
  
  # Allow focusing on specific tests with :focus
  config.filter_run_when_matching :focus
end
