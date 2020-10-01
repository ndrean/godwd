# Using setup:
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#

require 'fileutils'

workers     Integer(ENV['WEB_CONCURRENCY'] || 2)

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

# max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
# min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
# threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
# is Puma runs alone, then specifiy the port, otheriwse if NGINX, a unix socket
port       ENV.fetch("PORT") { 3002 }

app_dir = "/app" # File.expand_path("../..", __FILE__)

ENV.fetch('APP_DIR', app_dir.to_s)
# Specifies the `environment` that Puma will run in.
# HEROKU
environment ENV.fetch("RAILS_ENV") { "development" } 
# daemonize   true
# Specifies the `pidfile` that Puma will use.
pidfile     ENV.fetch("PIDFILE") { "#{app_dir}/tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# cf HEROKU
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#recommended-default-puma-process-and-thread-configuration

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Heroku
rackup      DefaultRackup


#### NGINX  buildpack ###
# bind ENV.fetch('PUMA_SOCK') { "unix://#{app_dir}/tmp/nginx.socket" }
bind "unix:///#{app_dir}/tmp/sockets/nginx.socket"

before_fork do |server,worker|
	FileUtils.touch('/tmp/app-initialized')
end
####


on_worker_boot do
    ActiveRecord::Base.establish_connection
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart do
    Sidekiq.redis.shutdown { |conn| conn.close }
end
