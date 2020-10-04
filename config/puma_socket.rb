require 'fileutils'

workers     Integer(ENV['WEB_CONCURRENCY'] || 2)

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count


environment ENV.fetch("RAILS_ENV") { "development" } 

app_dir =  File.expand_path("../..", __FILE__)
pidfile     ENV.fetch("PIDFILE") { "#{app_dir}/tmp/pids/server.pid" }

preload_app!
rackup      DefaultRackup

bind "unix:////tmp/nginx.socket"

on_worker_fork { FileUtils.touch('/tmp/app-initialized') }

on_worker_boot { ActiveRecord::Base.establish_connection }
 

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart do
    Sidekiq.redis.shutdown { |conn| conn.close }
end
