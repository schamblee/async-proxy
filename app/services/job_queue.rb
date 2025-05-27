class JobQueue
  class UpstreamError < StandardError; end

  TIMEOUT = 10 # seconds
  WAIT_LIST_LOCK = Mutex.new
  WAITING_JOBS = {}

  PUBLIC_URL = ENV["PUBLIC_URL"] || "http://localhost:4567/proxy"
  UPSTREAM_URL = "http://jobs.asgateway.com/start"

  def self.enqueue(account:, http_pool:)
    job_data = start_job(account, http_pool)
    job_id = job_data["id"]

    # Create lock and condition variable for this job
    wait_lock = Mutex.new
    wait_signal = ConditionVariable.new

    # Store synchronization objects for this job
    WAIT_LIST_LOCK.synchronize do
      WAITING_JOBS[job_id] = {
        lock: wait_lock,
        signal: wait_signal,
        result: nil
      }
    end

    # Wait for the job result or timeout
    wait_for_result(job_id, wait_lock, wait_signal)
  end

  def self.wait_for_result(job_id, wait_lock, wait_signal)
    did_timeout = false

    wait_lock.synchronize do
      # Wait for the signal or until timeout
      did_timeout = true unless wait_signal.wait(wait_lock, TIMEOUT)
    end

    WAIT_LIST_LOCK.synchronize do
      job_data = WAITING_JOBS.delete(job_id)
      result = job_data && job_data[:result]

      if did_timeout && result.nil?
        raise Timeout::Error, "Job #{job_id} timed out"
      end

      result
    end
  end

  def self.store_result(job_id, result)
    WAIT_LIST_LOCK.synchronize do
      job = WAITING_JOBS[job_id]
      return false unless job

      # Store result and notify any waiting thread
      job[:result] = result
      job[:lock].synchronize { job[:signal].broadcast }

      true
    end
  end

  def self.start_job(account, http_pool)
    uri = URI(UPSTREAM_URL)

    req = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json" })
    req.body = JSON.generate({
      callback: "#{PUBLIC_URL}/callback",
      wait: false,
      account: account
    })

    response = nil

    http_pool.with do |http|
      response = http.request(uri, req)
    end

    if response.code.to_i >= 400
      raise UpstreamError, "Failed to start job: #{response.body}"
    end

    JSON.parse(response.body)
  end
end
