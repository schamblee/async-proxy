require "spec_helper"
require_relative "../../app/controllers/application_controller"
require_relative "../../app/controllers/proxy_controller"
RSpec.describe "ProxyController" do
  include Rack::Test::Methods

  def app
    ProxyController
  end

  let(:valid_payload) { { account: "test@example.com" }.to_json }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /proxy" do
    context "with valid JSON" do
      it "returns 504 if job times out" do
        post "/proxy", valid_payload, headers
        expect(last_response.status).to eq(504)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to include("timed out")
      end
    end

    context "with invalid JSON" do
      it "returns 400 with error" do
        post "/proxy", "invalid-json", headers
        expect(last_response.status).to eq(400)
        json = JSON.parse(last_response.body)
        expect(json["error"]).to eq("Invalid JSON")
      end
    end
  end

  describe "POST /proxy/callback" do
    it "returns 200 even if job ID is unknown (timeout happened)" do
      post "/proxy/callback", { id: "nonexistent-job", status: "done" }.to_json, headers
      expect(last_response.status).to eq(200)
    end

    it "returns 400 for missing job ID" do
      post "/proxy/callback", { status: "done" }.to_json, headers
      expect(last_response.status).to eq(400)
      json = JSON.parse(last_response.body)
      expect(json["error"]).to include("Missing job ID")
    end
  end
end
