ENV["RACK_ENV"] ||= "development"

require "bundler"
Bundler.require(:default, ENV["RACK_ENV"])

# Load the application environment
require './app/services/job_queue'
require "./app/controllers/application_controller"
require "./app/controllers/proxy_controller"
