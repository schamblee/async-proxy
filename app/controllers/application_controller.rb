require "sinatra/base"
require "sinatra/json"
require "sinatra/namespace"

class ApplicationController < Sinatra::Base
  register Sinatra::Namespace

  configure do
    set :server, "webrick"
    set :host_authorization, { permitted_hosts: [] }
  end

  options "*" do
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
    json({ status: "OK", timestamp: Time.now })
  end
end
