#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
# rm -f /myapp/tmp/pids/server.pid

rm -f tmp/pids/server.pid

bundle exec puma -C config/puma.rb

bundle exec sidekiq -C config/sidekiq.yml

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"