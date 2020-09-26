# Using setup:
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#

# require 'fileutils'

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3001 }

# Specifies the `environment` that Puma will run in.
# HEROKU
environment ENV.fetch("RAILS_ENV") || "development" 

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# cf HEROKU
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#recommended-default-puma-process-and-thread-configuration
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
#worker 1
# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Heroku
rackup DefaultRackup



before_fork do 
    @sidekiq_pid ||= spawn('bundle exec sidekiq -t 2')
end

#### NGINX  buildpack ###

# bind ENV.fetch('PUMA_SOCK') { 'unix:///tmp/nginx.socket' }
# # listen '/tmp/nginx.socket'
# before_fork do |server,worker|
# 	FileUtils.touch('/tmp/app-initialized')
# end
####


on_worker_boot do
    ActiveRecord::Base.establish_connection
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart do
    Sidekiq.redis.shutdown { |conn| conn.close }
end
