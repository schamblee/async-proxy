require "./config/environment"

desc "Start the development server with reloading"
task :dev do
  ENV["RACK_ENV"] = "development"
  exec "bundle exec rerun 'rackup -p 4567'"
end
