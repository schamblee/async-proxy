class ApplicationController < ActionController::API
  # Ensure we always return JSON for errors
  rescue_from StandardError do |e|
    Rails.logger.error "Error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: { error: "Internal server error: #{e.message}" }, status: 500
  end
  
  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: 400
  end

  def json_request?
    request.format.json?
  end
end
