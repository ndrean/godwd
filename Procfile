release: bundle exec rails server
web:  bin/start-nginx-solo bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C ./config/sidekiq.yml
redis: redis-server --port 6379