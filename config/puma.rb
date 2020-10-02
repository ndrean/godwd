# Using setup:
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

workers     Integer(ENV['WEB_CONCURRENCY'] || 1)

threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

port  ENV['PORT'] || 3001

environment ENV.fetch("RAILS_ENV") { "development" } 

preload_app!

# Heroku
rackup      DefaultRackup

on_worker_boot do
    ActiveRecord::Base.establish_connection
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

on_restart do
    Sidekiq.redis.shutdown { |conn| conn.close }
end
