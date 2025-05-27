class ApplicationController < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::JSON

  configure do
    # Using webrick to ensure thread management is handled within the application layer; would not use in production
    set :server, "webrick"
    # Allowing all hosts intentionally; update `permitted_hosts` for specific restrictions
    set :host_authorization, { permitted_hosts: [] }
  end

  options "*" do
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    200
  end

  error 404 do
    json({ error: "Not Found" })
  end
  
  error 500 do
    json({ error: "Internal Server Error" })
  end
  
  # Health check
  get "/health" do
    json({ status: "OK", timestamp: Time.now.utc })
  end
end
