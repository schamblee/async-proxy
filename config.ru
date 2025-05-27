require "./config/environment"

if ENV["RACK_ENV"] == "development"
  use Rack::Reloader
end

run Rack::Cascade.new([ProxyController, ApplicationController])
