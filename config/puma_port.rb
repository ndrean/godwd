require 'fileutils'

workers     Integer(ENV['WEB_CONCURRENCY'] || 2)

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

port      3001 

app_dir =  File.expand_path("../..", __FILE__)
environment ENV.fetch("RAILS_ENV") { "development" } 

# Specifies the `pidfile` that Puma will use.
pidfile     ENV.fetch("PIDFILE") { "#{app_dir}/tmp/pids/server.pid" }

preload_app!
rackup      DefaultRackup

# on_worker_fork { FileUtils.touch('/tmp/app-initialized') } 

# on_worker_boot { ActiveRecord::Base.establish_connection }

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart { Sidekiq.redis.shutdown(&:close) }
