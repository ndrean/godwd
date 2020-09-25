
web:  bin/start-nginx-solo bundle exec puma -C config/puma.rb
release: bundle exec rails server $(PORT: -5000)
worker: bundle exec sidekiq -C ./config/sidekiq.yml
redis: redis-server --port 6379