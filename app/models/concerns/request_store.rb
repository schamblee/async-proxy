require 'concurrent'

class RequestStore
  include Singleton
  
  def initialize
    @requests = Concurrent::Map.new
  end
  
  def store_request(request_id, request)
    @requests[request_id] = {
      completed: Concurrent::AtomicBoolean.new(false),
      result: Concurrent::AtomicReference.new(nil),
      started_at: Time.now
    }
  end
  
  def wait_for_completion(request_id, timeout: 10)
    request_data = @requests[request_id]
    return { error: 'Request not found' } unless request_data
    
    # Poll for completion
    deadline = Time.now + timeout
    while Time.now < deadline
      if request_data[:completed].true?
        result = request_data[:result].get
        @requests.delete(request_id)
        return result
      end
      sleep 0.01
    end
    
    # Timeout
    @requests.delete(request_id)
    { error: 'Request timed out' }
  end
  
  def complete_request(request_id, result)
    request_data = @requests[request_id]
    return unless request_data
    
    request_data[:result].set(result)
    request_data[:completed].make_true
  end
end
