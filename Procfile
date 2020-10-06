
# Heroku set up

web: bin/start-nginx bundle exec puma -C config/puma_heroku.rb

worker: bundle exec sidekiq -C config/sidekiq.yml
