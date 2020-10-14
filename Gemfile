source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.2'
# Use postgresql as the database for Active Record

# PotsgreSQL
gem 'pg', '>= 0.18', '< 2.0'

# Use Puma as the app server
gem 'puma', '~> 4.1'

gem 'rack-brotli'

# gem 'fast_jsonapi'

# Use Sidekiq for background processing
gem 'sidekiq'
gem 'sidekiq-failures', '~> 1.0'

# Use Redis adapter for Sidekiq
gem 'redis', '~> 4.0'
gem 'hiredis'

# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'
gem 'jwt', '~> 2.2.1'
gem "knock", github: "nsarno/knock", branch: "master",
    ref: "9214cd027422df8dc31eb67c60032fbbf8fc100b"

# Use Mailgun for sending mails: config DNS in OVH.
#gem 'mailgun-ruby'



# Use Cloudinary services for storing images
gem 'cloudinary'


# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

gem 'faker'#, :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
# gem "oink"
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'dotenv-rails'
  # gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
  # First step for testing mails
  gem 'letter_opener'
  # Help to kill N+1 queries and unused eager loading
  gem 'bullet'

end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
