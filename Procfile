

web: bin/rails server -p 3001 -e $RAILS_ENV
worker: bundle exec sidekiq -C config/sidekiq.yml
redis: redis-server --port 6379