
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-production}
worker: bundle exec sidekiq -C config/sidekiq.yml
redis: redis-server --port 6379