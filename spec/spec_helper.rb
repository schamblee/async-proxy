ENV["RACK_ENV"] = "test"

require "rack/test"
require "rspec"
require_relative "../config/environment"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  
  # Pretty print test output
  config.formatter = :documentation
end
