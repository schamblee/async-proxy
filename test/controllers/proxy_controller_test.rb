require "test_helper"

class ProxyControllerTest < ActionDispatch::IntegrationTest
  def setup
    @account = "test@example.com"
    @job_server_url = "http://jobs.asgateway.com/start"
  end
  
  def teardown
    WebMock.reset!
  end
  
  test "validates account parameter is required" do
    post "/start",
      params: { wait: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    
    assert_response :bad_request
    data = JSON.parse(@response.body)
    assert_match /account.*required/i, data["error"]
  end
  
  test "health check endpoint works" do
    get "/up"
    assert_response :success
  end
end
