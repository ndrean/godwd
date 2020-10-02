# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

require 'fileutils'

workers     ENV.fetch('WEB_CONCURRENCY') {1}

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

port        ENV['PORT']

environment ENV.fetch("RAILS_ENV") { "development" } 

preload_app!

# Heroku
rackup      DefaultRackup

# bind "unix:///tmp/nginx.socket"
# before_fork do |server,worker|
on_worker_fork do
	FileUtils.touch('/tmp/app-initialized')
end

on_worker_boot do
    ActiveRecord::Base.establish_connection
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart do
    Sidekiq.redis.shutdown { |conn| conn.close }
end
