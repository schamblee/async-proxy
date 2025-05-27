# Async Proxy

A Ruby (Sinatra) application built for proxying HTTP requests asynchronously using a connection pool and job queue. The app implements two endpoints:

- `POST /proxy`: Accepts a JSON payload with an `account` key, enqueues a job, and returns the result as JSON.
- `POST /proxy/callback`: Accepts job results via callback, validates the payload, and stores the result.

Error handling is included for invalid JSON, timeouts, and server errors.

## Local set up

1. Install dependencies.

```
bundle install
```

1. Set up HTTP tunnel to expose a public URL of the local environment.

I used http-tunnels. Run the following and copy the URL it provides:

```
ssh -R 80:localhost:4567 localhost.run
```

2. Set the PUBLIC_URL enironment variable and start the server.

In a new terminal, run:

```
export PUBLIC_URL=<url from step 1>/proxy
bundle exec rake dev
```

3. Run the jobclient.

In a third terminal, run:

```
export PUBLIC_URL=<url from step 1>/proxy
./vendor/jobclient --url $PUBLIC_URL --account test
```

## Reflections

### 1. Error handling gaps
_What class of errors or conditions from the job server does your proxy service not account
for?_

* **Idempotency**: No detection or handling of duplicate job IDs, potentially causing unpredictable client responses if values change
* **Monitoring**: No instrumentation to track request volumes, errors, or performance metrics
* **Request throttling**: No handling for rate limiting from the job server
* **Network errors**: Connection timeouts and other network failures lack retry logic
* **Callback authentication**: No verification mechanism to ensure webhook callbacks are legitimate
* **Payload validation**: Missing required fields (such as `account`) aren't properly validated and reported
* **Memory leaks**: No cleanup mechanism for abandoned or timed-out jobs and potential memory leaks if job server webhooks never fire
* **Thread starvation**: Excessive condition variable waits could lead to resource exhaustion
* **Process resilience**: In-memory job queue means all in-progress jobs are lost on crash/restart

### 2. Future iterations
_How would you update the proxy service in future development iterations to account for
these error conditions? Not looking for a code or language-specific answer here - just talk in
general concepts and patterns to implement for each error condition._

#### Data Integrity
* **Schema validation:**
  * Validate job server responses before processing
  * Verify client request parameters against required schema
  * Implement proper error responses for invalid inputs (e.g. missing `account` or `id` params)
* **Idempotency checks:** Track processed callbacks to detect and handle duplicates

#### Reliability
* **Retry mechanism:** Implement exponential backoff with jitter for failed requests
* **Rate limit handling:** Detect HTTP 429 responses and adjust request pacing accordingly
* **Dead-letter queue:** Persist failed jobs for later analysis or retry
* **Data persistence:** Use Redis or database to survive process crashes/restarts

#### Operational Improvements
* **Metrics and alerting:** Add instrumentation for performance tracking and incident detection
* **Automatic cleanup:** Implement TTL for unprocessed jobs to prevent memory bloat
* **Security enhancements:** Add token-based callback verification to prevent spoofing

### 3. Scaling limitations
_If the requirements for the proxy service, still running as a single process on a single node,
were increased to handle 10X, 100X, 1000X, etc... concurrent requests, what limitations
would the current implementation hit? Assume the job server itself will never be the limiting
factor._

* **Memory usage:** In-memory job storage scales linearly with active jobs
* **Thread contention:** Mutex and ConditionVariable coordination becomes inefficient at high concurrency
* **HTTP connection limits:** Fixed connection pool (10) creates bottlenecks for outbound requests
* **Ruby's Global VM Lock (GVL):** Prevents true parallel execution even across multiple threads
* **CPU-bound coordination:** Thread management overhead increases with concurrent jobs
* **Timeout precision:** High thread counts cause timing inaccuracies and potential cascading delays
* **Single-process design:** Lacks ability to distribute load across CPU cores

### 4. Distributed system archetecture
_If your implementation graduates from the prototype phase and needs to be deployed into
production, what changes will need to be made to support running as a distributed service
across several disparate nodes? Imagine five instances of your proxy service running, each
on one of the five different nodes - what changes will you have to make to your app to
support this mode of operation?_

* **Distributed data store:** Replace in-memory hash with Redis or database for cross-node persistence
* **Event broadcasting:** Use pub/sub mechanism (such as Redis) for cross-node signaling
* **Callback routing:** Ensure webhooks reach the correct node via consistent load balancer configuration
* **Unique job tracking:** Generate UUIDs for each job to prevent duplicate processing
* **Session resilience:** Persist in-flight job state to survive node failures
* **Service discovery:** Implement registration mechanism for dynamic node management
* **Health monitoring:** Use health endpoint to regularly check the the server is running and have an alert in place if abnormalities are detected.
* **Load balancing:** Distribute incoming client requests across available nodes

### 5. How can we improve this work sample?
This assessment effectively evaluates distributed systems knowledge. My only suggestions would be to provide a clear time-box expectation and have an easier way to submit the work sample (supply a link to a github repo, etc.)

I've used [Hatchways](https://www.hatchways.io/) for a coding challenge in the past and have found it very convenient.

### 6. AI Usage
_If you choose to use AI for ANY portion of your submission, we'd love to hear your reasoning
as to why or why not, how you used it, how much, or any other insight that you feel is
valuable for us to have._

I used AI selectively during this project, primarily for:

* Brainstorming modularization strategies
* Validating Ruby concurrency patterns with Mutex and ConditionVariable
* Quick reference checks on Rack/Sinatra testing patterns

I deliberately avoided having AI generate the complete solution to ensure I fully understood the app design. AI served as a research accelerator for specific patterns without replacing my own problem-solving process.
