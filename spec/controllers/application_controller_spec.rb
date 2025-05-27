require "spec_helper"
require_relative "../../app/controllers/application_controller"

RSpec.describe "ApplicationController" do
  include Rack::Test::Methods

  def app
    ApplicationController
  end

  describe "GET /health" do
    it "returns OK" do
      get "/health"
      expect(last_response.status).to eq(200)
      
      body = JSON.parse(last_response.body)
      expect(body["status"]).to eq("OK")
    end
  end
end
