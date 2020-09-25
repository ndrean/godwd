
web:  bin/start-nginx-solo bundle exec rails server $(PORT: -5000)
worker: bundle exec sidekiq -C ./config/sidekiq.yml
redis: redis-server --port 6379