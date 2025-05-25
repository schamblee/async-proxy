Rails.application.routes.draw do
  post "/" => "proxy#start"
  post "/start" => "proxy#start"
  post "/callback/:request_id" => "proxy#callback"
  get "up" => "rails/health#show", as: :rails_health_check
end
