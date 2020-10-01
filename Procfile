
web: bin/start-nginx-solo bundle exec puma -b 0.0.0.1:3002 --config config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
