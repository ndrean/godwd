api: bundle exec bin/rails server -p 3001
worker: bundle exec sidekiq -C ./config/sidekiq.yml
worker: bundle exec sidekiq -e production -t 25 -C config/sidekiq.yml
redis: redis-server --port 6379