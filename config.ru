# config.ru
require "./config/environment"

if ENV["RACK_ENV"] == "development"
  use Rack::Reloader
end

run ApplicationController
