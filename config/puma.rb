#### version tcp/ip ####

require 'fileutils'

# puma in single mode => set workers to 'O'
workers     ENV.fetch('WEB_CONCURRENCY') { 2 }

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

port        3001    

# value overwritten by Heroku
#environment ENV.fetch("RAILS_ENV") { "development" } ##


preload_app! ##
rackup      DefaultRackup ##

on_worker_fork { FileUtils.touch('/tmp/app-initialized') } ##
	

# 2 workers => cluster mode
# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted, this block will be run. If you are using the `preload_app!`
# option, you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, as Ruby
# cannot share connections between processes.
on_worker_boot { ActiveRecord::Base.establish_connection }
    


plugin :tmp_restart

on_restart { Sidekiq.redis.shutdown(&:close) }
