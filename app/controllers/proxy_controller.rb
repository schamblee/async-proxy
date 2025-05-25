class ProxyController < ApplicationController
  JOB_SERVER_URL = 'http://jobs.asgateway.com/start'
  
  def start
    Rails.logger.info "Start action called with params: #{params.inspect}"
    
    account = params[:account]
    
    unless account.present?
      return render json: { error: 'Account parameter required' }, status: 400
    end
    
    request_id = SecureRandom.hex(16)
    
    # Store the request
    RequestStore.instance.store_request(request_id, request)
    
    # Submit job asynchronously
    Thread.new do
      begin
        callback_url_value = callback_url(request_id)
        Rails.logger.info "Submitting job with callback URL: #{callback_url_value}"
        
        response = HTTParty.post(
          JOB_SERVER_URL,
          body: {
            account: account,
            wait: false,
            callback: callback_url_value
          }.to_json,
          headers: { 'Content-Type' => 'application/json' },
          timeout: 5
        )
        
        Rails.logger.info "Job server response: #{response.code} - #{response.body}"
        
        if response.code != 200
          RequestStore.instance.complete_request(request_id, {
            error: "Job server error: #{response.code}"
          })
        end
      rescue => e
        Rails.logger.error "Failed to submit job: #{e.message}"
        Rails.logger.error e.backtrace.first(5).join("\n")
        RequestStore.instance.complete_request(request_id, {
          error: "Failed to submit job: #{e.message}"
        })
      end
    end
    
    # Wait for callback
    result = RequestStore.instance.wait_for_completion(request_id)
    
    if result[:error]
      render json: { error: result[:error] }, status: 500
    else
      render json: result[:data]
    end
  rescue => e
    Rails.logger.error "Error in start action: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    render json: { error: "Internal error: #{e.message}" }, status: 500
  end
  
  def callback
    request_id = params[:request_id]
    Rails.logger.info "Received callback for request_id: #{request_id}"
    
    begin
      callback_data = JSON.parse(request.body.read)
      Rails.logger.info "Callback data: #{callback_data.inspect}"
      
      RequestStore.instance.complete_request(request_id, {
        data: callback_data
      })
      
      head :ok
    rescue => e
      Rails.logger.error "Callback error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      head :bad_request
    end
  end
  
  private
  
  def callback_url(request_id)
    if ENV['NGROK_URL'].present?
      "#{ENV['NGROK_URL']}/callback/#{request_id}"
    else
      "#{request.protocol}#{request.host_with_port}/callback/#{request_id}"
    end
  end
end
