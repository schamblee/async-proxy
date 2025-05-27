# Async Proxy

A Ruby (Sinatra) controller for proxying HTTP requests asynchronously using a connection pool and job queue.  
This controller provides two endpoints:

- `POST /proxy`: Accepts a JSON payload with an `account` key, enqueues a job, and returns the result as JSON.
- `POST /proxy/callback`: Accepts job results via callback, validates the payload, and stores the result.

Error handling is included for invalid JSON, timeouts, and server errors.
