

web: bundle exec rails s -p $(port: 5000)
worker: bundle exec sidekiq -C config/sidekiq.yml
redis: redis-server --port 6379