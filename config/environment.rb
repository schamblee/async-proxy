# Set the environment variable
ENV["RACK_ENV"] ||= "development"

require "bundler"
Bundler.require(:default, ENV["RACK_ENV"])

# Load controllers
require "./app/controllers/application_controller"
Dir["./app/controllers/*.rb"].each { |file| require file }
