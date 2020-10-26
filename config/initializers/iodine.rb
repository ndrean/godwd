# Iodine setup - use conditional setup to allow command-line arguments to override these:
if(defined?(Iodine))
  Iodine.threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i if Iodine.threads.zero?
  Iodine.workers = ENV.fetch("WEB_CONCURRENCY", 2).to_i if Iodine.workers.zero?
  Iodine::DEFAULT_SETTINGS[:port] ||= ENV.fetch("PORT") if ENV.fetch("PORT")
  $redis = Iodine::PubSub::Redis.new(ENV["REDIS_URL"])
  # Iodine.start
end