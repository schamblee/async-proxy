RSpec.describe JobQueue do
  let(:account) { "test_account" }
  let(:job_id) { "job-123" }
  let(:job_result) { { "result" => "success" } }
  let(:http_pool) { double("http_pool") }
  let(:http) { double("http") }
  let(:response) { double("response", code: "200", body: { id: job_id }.to_json) }

  before do
    allow(http_pool).to receive(:with).and_yield(http)
    allow(http).to receive(:request).and_return(response)
    JobQueue::WAITING_JOBS.clear
  end

  describe "enqueue" do
    it "starts a job and waits for result" do
      allow(JobQueue).to receive(:wait_for_result).and_return(job_result)
      expect(JobQueue).to receive(:start_job).with(account, http_pool).and_return({ "id" => job_id })
      expect(JobQueue).to receive(:wait_for_result)
      result = JobQueue.enqueue(account: account, http_pool: http_pool)
      expect(result).to eq(job_result)
    end
  end

  describe "wait_for_result" do
    it "returns result if present before timeout" do
      wait_lock = Mutex.new
      wait_signal = ConditionVariable.new
      JobQueue::WAIT_LIST_LOCK.synchronize do
        JobQueue::WAITING_JOBS[job_id] = {
          lock: wait_lock,
          signal: wait_signal,
          result: job_result
        }
      end
      expect(JobQueue.wait_for_result(job_id, wait_lock, wait_signal)).to eq(job_result)
    end

    it "raises Timeout::Error if result is not set" do
      wait_lock = Mutex.new
      wait_signal = ConditionVariable.new
      JobQueue::WAIT_LIST_LOCK.synchronize do
        JobQueue::WAITING_JOBS[job_id] = {
          lock: wait_lock,
          signal: wait_signal,
          result: nil
        }
      end
      allow_any_instance_of(ConditionVariable).to receive(:wait).and_return(false)
      expect {
        JobQueue.wait_for_result(job_id, wait_lock, wait_signal)
      }.to raise_error(Timeout::Error)
    end
  end

  describe "store_result" do
    it "stores result and broadcasts signal" do
      wait_lock = Mutex.new
      wait_signal = ConditionVariable.new
      JobQueue::WAIT_LIST_LOCK.synchronize do
        JobQueue::WAITING_JOBS[job_id] = {
          lock: wait_lock,
          signal: wait_signal,
          result: nil
        }
      end
      expect(wait_signal).to receive(:broadcast)
      expect(JobQueue.store_result(job_id, job_result)).to eq(true)
      expect(JobQueue::WAITING_JOBS[job_id][:result]).to eq(job_result)
    end

    it "returns false if job_id not found" do
      expect(JobQueue.store_result("missing-job", job_result)).to eq(false)
    end
  end

  describe "start_job" do
    it "sends a POST request and returns parsed response" do
      expect(http_pool).to receive(:with).and_yield(http)
      expect(http).to receive(:request).and_return(response)
      expect(JobQueue.start_job(account, http_pool)).to eq({ "id" => job_id })
    end

    it "raises UpstreamError on error response" do
      error_response = double("response", code: "500", body: "error")
      allow(http).to receive(:request).and_return(error_response)
      expect {
        JobQueue.start_job(account, http_pool)
      }.to raise_error(JobQueue::UpstreamError)
    end
  end
end