class ProxyController < ApplicationController
  HTTP_POOL = ConnectionPool.new(size: 10, timeout: 5) do
    Net::HTTP::Persistent.new(name: "proxy-client")
  end

  namespace "/proxy" do
    post "" do
      content_type :json

      begin
        data = JSON.parse(request.body.read)
        account = data["account"]

        result = JobQueue.enqueue(account:, http_pool: HTTP_POOL)
        [200, result.to_json]
      rescue JSON::ParserError
        halt 400, { error: "Invalid JSON" }.to_json
      rescue Timeout::Error => e
        halt 504, { error: e.message }.to_json
      rescue => e
        puts "[ERROR] #{e.message}"
        halt 500, { error: "Internal server error" }.to_json
      end
    end

    post "/callback" do
      begin
        data = JSON.parse(request.body.read)
        job_id = data["id"]
        halt 400, { error: "Missing job ID in callback" }.to_json unless job_id
        stored = JobQueue.store_result(job_id, data)
        stored
        [200, "OK"]
      rescue JSON::ParserError
        halt 400, { error: "Invalid JSON" }.to_json
      rescue => e
        puts "[Callback ERROR] #{e.message}"
        halt 500, { error: "Callback error" }.to_json
      end
    end
  end
end
