class ProxyController < ApplicationController
  namespace "/proxy" do
    post "/" do
      # TODO: Implement proxy logic
      halt 501, json({ error: "Proxy functionality not implemented yet" })
    end

    post "/callback" do
      # TODO: Implement callback logic
      halt 501, json({ error: "Callback functionality not implemented yet" })
    end
  end
end
