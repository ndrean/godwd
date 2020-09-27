if Rails.env.development?
  Sidekiq.configure_server do |config|
    # for provider/Heroku, need to set an env variable that provider changes
    config.redis = { url: ENV['REDIS_URL'] }

  end
end

if Rails.env.production?
  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 1, network_timeout: 5 }
  end

  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 9, network_timeout: 5 }
  end
end
