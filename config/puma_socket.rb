require 'fileutils'

workers     Integer(ENV['WEB_CONCURRENCY'] || 0)

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count


environment ENV.fetch("RAILS_ENV") { "development" } 

app_dir =  File.expand_path("../..", __FILE__)
pidfile     ENV.fetch("PIDFILE") { "#{app_dir}/tmp/pids/server.pid" }

preload_app!
rackup      DefaultRackup

bind "unix://#{app_dir}/tmp/sockets/nginx.socket"

on_worker_fork { FileUtils.touch('/tmp/app-initialized') }

on_worker_boot { ActiveRecord::Base.establish_connection }
 

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart { Sidekiq.redis.shutdown(&:close)  }
