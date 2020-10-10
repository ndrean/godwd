# Details

The Rails api can be run with `rails server` and navigate to `localhost:3001/api/v1/events`.
You can run `foreman start -f Procfile_nginx_port.rb` and navigate to `localhost:8000/api/v1/events`: it is reverse-proxied with Nginx.
You can run `docker-compose up` and navigate to `localhost:8080/api/v1/events`: the Docker container exposes 8080 > 80 and Rails via 3001:3001.

This Rails back end uses:

- Postgres as database,
- Sidekiq with Redis as the ActiveJob adapter
- Knock (with BCrypt and JWT) for authentification
- Cloudinary (without ActiveStorage) for storing images. The upload is done directly to Cloudinary by the front end. The front end sends the url of the image, and the back end saves it. The back end only deletes the image async with a Sidekiq worker.

# Database structure

3 tables, where 'events' is a joint table.

- The field `events.participants` has a format Postgres of `jsonb`, an array of type `{email: 'toto@test.com', notif:"false", ptoken:"wmkm234kxkl"}`

- `end_gps` and `start_gps` are arrays of 2 decimals, `[45.23424,1.234234]`

- a user has the field `password_digest` even if we use the field `password`: the gem `bcrypt` saves it encrypted (the key is the Rails `secret_bse_key`).
- the fields `uid` and `access-token` are copies of a users's Facebook credentials.
- the `confirm_token` is used on 'sign up': the `Knock` gem generates a token that is saved in the db, and sent in a link by email in the user. when the confirms, the db reads this token and confirms the user.

![Database schema](https://github.com/ndrean/godwd/blob/master/public/goDownWind.png)

```
CREATE TABLE "events" (
  "id" varchar,
  "directCLurl" string,
  "publicID" string,
  "url" string,
  "participants" jsonb,
  "user_id" bigint,
  "itinary_id" bigint,
  "created_at" datetime,
  "updated_at" datetime,
  "comment" text
);

CREATE TABLE "itinaries" (
  "id" varchar,
  "date" date,
  "start" string,
  "end" string,
  "distance" decimal,
  "created_at" datetime,
  "updated_at" datetime,
  "end_gps" decimal,
  "start_gps" decimal
);

CREATE TABLE "users" (
  "id" varchar,
  "email" string,
  "password_digest" string,
  "confirm_token" string,
  "confirm_email" boolean,
  "access_token" string,
  "uid" string,
  "created_at" datetime,
  "updated_at" datetime
);

ALTER TABLE "itinaries" ADD CONSTRAINT "fk_rails_events_itinaries" FOREIGN KEY ("id") REFERENCES "events" ("itinary_id");

ALTER TABLE "users" ADD CONSTRAINT "fk_rails_events_users" FOREIGN KEY ("id") REFERENCES "events" ("user_id");
```

# schema.rb

<https://edgeguides.rubyonrails.org/active_record_migrations.html#schema-dumping-and-you>

```ruby
# /config/application.rb
config.active_record.schema_format :ruby
```

so we can do `rails db:schema.load` instead of running all the migrations with `rails db:migrate`.

Once `docker-compose up`, we can do:

```bash
docker-compose exec rails db:create
docker-compose exec web rails db:schema:load
docker-compose exec web rails db:seed
```

# HTTP Caching w/Rails

`api:rails: ConditionalGet`
This is a Rails API so only `if stale` is possible. -`if stale?` renders 'Completed 304 Not Modified in 33ms' or querries again when necessary.

Read:

<https://thoughtbot.com/blog/take-control-of-your-http-caching-in-rails>

<https://www.synbioz.com/blog/tech/du-cache-http-avec-les-etag-en-rails>
<https://blog.bigbinary.com/2016/03/08/rails-5-switches-from-strong-etags-to-weak-tags.html?utm_source=rubyweekly&utm_medium=email>

Other HTTP caching iwth Rails (non API):

- if request is `fresh_when(@variable)` Etag will render 304 Not modified response

- set HTTP Cache-Control header: `expires_in 2.hours, public: true`
  <https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-expires_in>

  <https://devcenter.heroku.com/articles/http-caching-ruby-rails#conditional-cache-headers>

# VPS for Rails

<https://mydigital-life.online/comment-installer-rails-sur-un-vps/>

# Async jobs:

- `ActiveJob`. Set `config.active_job.queue_adapter = :sidekiq` in `/config/environments/dev-prod.rb`, and use `perform_later` or `deliver_later`. We alos need to declare a class inheriting from `ApplicationJob`and defined `queure_as :mailer` for example. <https://github.com/mperham/sidekiq/wiki/Active+Job>

- or directly `Sidekiq`: example with RemoveDirectLink. Create a worker under `/app/workers/my_worker.rb` with `include Sidekiq::Worker` and use `perform_async` in the controller).

## Sidekiq setup

- added to '/config/application;rb`the declaration:`config.active_job.queue_adapter = :sidekiq` tells ActiveJob to use Sidekiq.

- Added `/config/sidekiq.rb` with `Redis`.

<https://github.com/mperham/sidekiq/wiki>
<https://enmanuelmedina.com/en/posts/rails-sidekiq-heroku>

When we defined the route:

```ruby
mount Sidekiq::Web => '/sidekiq'
```

then the sidekiq console is available at http://localhost:3001/sidekiq.

To run Sidekiq, we do:

```bash
bundle exec sidekiq --environment development -C config/sidekiq.yml
```

This will be a separate process for the process launcher `Foreman`:

```bash
worker: bundle exec sidekiq -C ./config/sidekiq.yml
```

# Mail background jobs

- gem 'mailgun-ruby` is usefull to get the info that a mail has been sent.
  <https://github.com/mailgun/mailgun-ruby>

We declare in '/config/application.rb' (for all environments):
`config.action_mailer.delivery_method = :smtp`

We don't use ActiveJob here to sedn async a mail, we use ActionMailer with Sidekiq and the method `deliver_later` <https://github.com/mperham/sidekiq/wiki/Active-Job>. We define a class (`EventMailer` and `UserMailer`, both inheriting from `ApplicationMailer`) with actions that will be used by the controller. Each method uses a `html.erb` view to be delivered via the mail protocole `smtp`. The views use the instance variables defined in the actions.

The mails are queued in a queue named `mailers` and Sidekiq uses a Redis db.

The usage of Redis is declared in the '/app/config/initializers/sidekiq.rb' and the gem 'redis'.

For Heroku, we need to set the config vars `REDIS_PROVIDER` and `REDIS_URL`.

For 'locahost', we set `REDIS_URL='redis://localhost:6379'`.

We use `Mailgun`. Once we have registered our domain, we set the DNS TXT & CNAME provided by Mailgun in the registar provider (OVH or AWS), and the SMTP data in `/config/initializers/smtp.rb`:

```ruby
ActionMailer::Base.smtp_settings = {
  address: 'smtp.mailgun.org',
  port: 587,
  domain: ENV['DOMAIN_NAME'], <=> "thedownwinder.com"
  user_name: ENV['SMTP_USER_NAME'], <=> "postmaster@thedownwinder.com"
  password: ENV['MAIL_APP_PASSWORD'], <=> "eac87f019exxxx"
  authentication: :plain,
  enable_starttls_auto: true
}
```

# Cloudinary remove with Sidekiq

- gem `Cloudinary`
  <https://cloudinary.com/documentation/rails_integration#rails_getting_started_guide>

<https://github.com/cloudinary/cloudinary_gem>

> credentials: they are passed manually to each call in the method, and added as `config vars` to Heroku. The `/config/cloudinary.yml` is not used since it doesn't accept `.env` variables.

We use the worker `RemoveDirectLink` to async remove a picture from Cloudinary by the Rails backend. We can use activeJob or directly a worker. The '/workers' folder is not read by Rails, only Sidekiq, declared

Here, we used a worker (without ActiveJob and `default queue`, just including `Sidekiq::Worker`) and use `perform_async`.

```ruby
 # /App/workers/remove_direct_link.rb
class RemoveDirectLink
  include Sidekiq::Worker

  def perform(event_publicID)
    auth = {
        cloud_name: Rails.application.credentials.CL[:CLOUD_NAME],
        api_key: Rails.application.credentials.CL[:API_KEY],
        api_secret: Rails.application.credentials.CL[:API_SECRET]
      }
    return if !event_publicID
    Cloudinary::Uploader.destroy(event_publicID, auth)
  end
end
```

We could also use ActiveJob (cf mails) by defining a class inheriting from `ApplicationJob` and specifying the 'queue' and use `deliver_later`. Here, we use the Cloudinary method `destroy`:

<https://cloudinary.com/documentation/image_upload_api_reference#destroy_method>

```
# /app/jobs/remove_direct_link.rb
class RemoveDirectLink < ApplicationJob
  queue_as :default

  def perform(event_publicID)
    auth = {
        cloud_name: ENV['CL_CLOUD_NAME'],
        api_key: ENV['CL_API_KEY'],
        api_secret: ENV['CL_API_SECRET']
      }

    return if !event_publicID
    Cloudinary::Uploader.destroy(event_publicID, auth)
  end
end
```

# Puma port setup

React will run on '3000' and Rails will run on port '3001'

```ruby
# /config/puma.rb
port        ENV.fetch("PORT") { 3001 }
```

# Bootsnap issue

<https://github.com/Shopify/bootsnap/issues/262>

# CORS

CORS stands for Cross-Origin Resource Sharing, a standard that lets developers specify who can access the assets on a server and what HTTP requests are accepted. For example, a restrictive 'same-origin' policy would prevent your Rails API at localhost:3001 from sending and receiving data to your front-end at localhost:3000.

```ruby
# /config/application.rb
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource ‘*’, headers: :any, methods: [:get, :post, :options]
  end
end
```

# Sidekiq, Redis setup

<https://manuelvanrijn.nl/sidekiq-heroku-redis-calc/>

1 worker, 1 dyno, 5 web thread

```ruby
# /config/initializers/sidekiq.rb
if Rails.env.production?
  Sidekiq.configure_client do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 3, network_timeout: 5 }
  end

  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_URL'], size: 5, network_timeout: 5 }
  end
end
```

```ruby
# .env
REDIS_URL='redis://localhost:6379'

#/config/initializers/sidekiq.rb
...config.redis = { url: ENV['REDIS_URL'], size: 2 }
```

To run Redis, we do:

```bash
brew services redis-server
```

We declare another process for Foreman (Procfile):

```bash
redis: redis-server --port 6379
```

# Procfile & Foreman

foreman start -f ProcfileIwant

> Dev localhost mode:

```
api: bundle exec bin/rails server -p 3001
worker: bundle exec sidekiq -C ./config/sidekiq.yml
redis: redis-server --port 6379

```

> Heroku mode:

```
api: bundle exec bin/rails server -p 3001
worker: bundle exec sidekiq -C ./config/sidekiq.yml
```

- settings.config vars:

`REDIS_URL` will be set in 'setttings/config vars' after setting `REDIS_PROVIDER=REDISTOGO_URL` (free)

Set the keys `RAILS_MASTER_KEY` and `SECRET_KEY_BASE` (do `EDITOR="code ...wait" rails credentials:edit` to set)

The `DATABASE_URL` wil be set by Heroku.

# Compression

We use directly gzip or Brotli compression with Rails. For Brotli, use the gem `rack-brotli` and set:

```ruby
#/config.application.rb
  config.middleware.use Rack::Deflater
  config.middleware.use Rack::Brotli
```

<https://pawelurbanek.com/rails-gzip-brotli-compression>

Since we use `Nginx`, we will use the inbuild gzip service to we delegate the data compression to nginx.

# Arrays in PostgreSQL

<https://stackoverflow.com/questions/63404637/rails-submitting-array-to-postgres>

To accept an array, we need to separate between the ',' when we read the params in the controller.

```ruby
if params[:event][:itinary_attributes][:start_gps]
  params[:event][:itinary_attributes][:start_gps] = params[:event][:itinary_attributes][:start_gps][0].split(',')
  params[:event][:itinary_attributes][:end_gps] = params[:event][:itinary_attributes][:end_gps][0].split(',')
end
```

We can also do the job directly in React: if we read an array `start_gps=[45,1]`, then to pass into `event:{itinary_attributes: {start_gps: [], end_gps: [] } }`, we do:

```js
fd.append("event[itinary_attributes][start_gps][]", itinary.start_gps[0] || "");
fd.append("event[itinary_attributes][start_gps][]", itinary.start_gps[1] || "");
fd.append("event[itinary_attributes][end_gps][]", itinary.end_gps[0] || "");
fd.append("event[itinary_attributes][end_gps][]", itinary.end_gps[1] || "");
```

# Running multiple processes

Use `foreman`

The `database.yml` musn't use the key `db` (or set `localhost`)

# Docker

<https://stackoverflow.com/questions/54383233/how-to-dockerize-a-rails-application-with-mysql-nginx-and-cron-tasks>

```
- app
  - config
     database.yml
     puma.rb
  - docker
    - app
      Dockerfile
    - web
      Dockerfile
      nginx.conf
  docker-compose.yml
  .dockerignore
```

- need to add `host: db` in `database.yml` in lieu of `host: localhost` when working with localhost & foreman

- sequence `docker build .`, then `docker-compose up` one by one, `db`, then `sidekiq`, then `web`(otherwise you get an error due to `Bootsnap`).

- the db is created, then `docker-compose exec web rails db:schema:load` and `db:seed`.

- Note: need to set `POSTGRES_PASSWORD: xxx` in the service `web|environment`

- get IPAdress with `docker inspect <containerID> | grep `IPAddress`(and the container Id is given in the list`docker ps -a`)

```bash
rm -rf tmp/*
docker rm $(docker ps -q -a) -f
docker rmi $(docker images -q) -f
docker build .
docker-compose up --build
docker-compose up -d web
docker-compose up -d sidekiq
docker-compose exec web rake db:create
docker-compose exec web rake db:schema:load
docker-compose exec web rake db:seeds
```

Set the key `host: db` in `database.yml` where `db` is the name of the Postgresql service in `docker-compose.yml`.

<https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose>

Needs in `.env`:

- Postgres:

```
# .env (Postgres Docker)
POSTGRES_USER=postgres
POTGRES_PASSWORD=postgres
```

- Redis:

Setup with <https://manuelvanrijn.nl/sidekiq-heroku-redis-calc/>

```
# .env
REDIS_URL='redis://localhost:6379'
```

Set for Postgres:

```
# .env
# Postgres Docker
POSTGRES_DB=godwd_development
POSTGRES_USER=postgres
POTGRES_PASSWORD=postgres
```

- create the database

```bash
docker-compose exec app rails db:create
docker-compse exec app rails db:schema:load # instead of db:migrate
docker-compose exec app rails db:seed
```

- connect from local machine to a PSQL db in Docker:
  <https://medium.com/better-programming/connect-from-local-machine-to-postgresql-docker-container-f785f00461a7>

## Docker commands

<https://thoughtbot.com/upcase/videos/intro-to-docker >

- list all containers: `docker container ls -a`

- list all containers's ids: `docker container ls -aq`

- stop all containers by passing a list of ids: `docker container stop $(docker container ls -aq)`

- remove all containers by passing a list of ids: `docker container rm $(docker container ls -aq)`

- To wipe Docker clean and start from scratch, enter the command:
  `docker container stop $(docker container ls –aq) && docker system prune –af ––volumes`

`docker run --link db -it postgres:9.4 psql -h db -U postgres`

# JWT, Knock

<https://www.techandstartup.org/tutorials/rails-react-jwt>

<https://davidgay.org/programming/jwt-auth-rails-6-knock/>

`Knock` uses the gems `jwt` and we add the gem `bcrypt` for the `has_secure_password` attribute in the `User`model.

- Install: `rails g

```ruby
payload = { id: 1, email: 'user@example.com' }
secret = Rails.application.credentials.secret_key_base
token = JWT.encode(payload, secret, 'HS256')
```

but we use the gem `Knock`

# Heroku Nginx buildpack

<https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-nginx>

The buildpack will not start NGINX until a file has been written to /tmp/app-initialized. Since NGINX binds to the dyno's $PORT and since the $PORT determines if the app can receive traffic, you can delay NGINX accepting traffic until your application is ready to handle it.

First:

- run `heroku buildpacks:add heroku-community/nginx`

- copy the `nginx.config.erb` in the '/config' folder.

- update the `puma.rb` code

- Procfile: `bin/start-nginx bundle exec puma -C ./config/puma.rb`

## Procfile

```bash
foreman start -f Procfile.dev
```

```
#/Procfile (for Heroku)
web:  bin/start-nginx bundle exec puma -C ./config/puma.rb
worker: bundle exec sidekiq -C ./config/sidekiq.yml

```

# Certbot - Nginx - Docker

<https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71>

# Old files

```ruby
class RegisterJob < ApplicationJob
  queue_as :mailers
  def perform(fb_user_email, fb_user_confirm_token)
    UserMailer.register(fb_user_email, fb_user_confirm_token).deliver
  end
end
```

- version with ActiveJob : use "RemoveDirectLink.perform_later" in controller

```ruby
class RemoveDirectLink < ApplicationJob
  queue_as :default
  def perform(event_publicID)
    auth = {
      cloud_name: Rails.application.credentials.CL[:CLOUD_NAME],
      api_key: Rails.application.credentials.CL[:API_KEY],
      api_secret: Rails.application.credentials.CL[:API_SECRET]
    }
    return if !event_publicID
    Cloudinary::Uploader.destroy(event_publicID, auth)
  end
end
```

# NGINX: reverse proxy

The main reason to set up Nginx as reverse proxy (client > Nginx > Puma/Rails) is to run your API server on a different network or IP then your front-end application is on. You can then secure this network and only allow traffic from the reverse proxy server.

## localhost settings:

They are 2 ways to let Puma and Nginx communicate: with unix sockets and tcp/ip domain names.

- unix socket:

```
#/config/puma.rb
!! remove port 3001 (port where Rails listens to)
bind "unix:///Users/utilisateur/code/rails/godwd/tmp/sockets/nginx.socket"
preload_app!
rackup      DefaultRackup
on_worker_boot { ActiveRecord::Base.establish_connection }


#/usr/local/etc/nginx/nginx.conf
http {
  upstream app_server {
    server unix:///Users/utilisateur/code/rails/godwd/tmp/sockets/nginx.socket fail_timeout=0;
  }

  server {
    listen       8080;

    location / {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_pass http://app_server;
    }
}
```

- tcp. (`127.0.0.1:3001` and not `0.0.0.:3001`):

```
#/app/config/puma.rb
port 3001
!!! remove bind "unix://..."

#/usr/local/etc/nginx/nginx.conf
http {
  upstream app_server {
    server 127.0.0.1:3001 fail_timeout=0;
  }
  server {
    listen          8000;

    location / {
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header  Host $host;
      proxy_redirect    off;
      proxy_pass        http://app_server;
    }
  }
}
```

- whitelisting `app_server` with: `Rails.application.config.host << "app_server"` in '#/config.development.rb'.
- Procfile `web: bundle exec puma -p 3001 -C config/puma.rb`

## Heroku production.

My app is located at `my-app.herokuapp.com` and I name-spaced my endpoints with '/api/v1'.

- buildpack : `$ heroku buildpacks:add heroku-community/nginx`,
- add to `Procfile`: `web: bin/start-nginx bundle exec puma --config config/puma.rb`
- add the file `/app/config/nginx.config.erb` using the biolerplate given by Heroku

> Mode tcp/ip

```ruby
# puma in single mode => set workers to 'O'
workers     ENV.fetch('WEB_CONCURRENCY') {2}
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

port        3001
preload_app!
rackup      DefaultRackup

# Heroku buildpack needs this file to initialize
on_worker_fork { FileUtils.touch('/tmp/app-initialized') }
on_worker_boot { ActiveRecord::Base.establish_connection }
plugin :tmp_restart
on_restart { Sidekiq.redis.shutdown(&:close) }
```

```
#/app/config/nginx.config.erb
daemon off;
[...]
http {
  [...]
  upstream app_server {
    server 127.0.0.1:3001 fail_timeout=0;
 	}

  server {
    listen <%= ENV['PORT'] %>;
    [...]

    location / {
      try_files $uri @rails;
    }

    location / {
      proxy_set_header  X-Real-IP  $remote_addr;
      proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_pass http://app_server;
    }
  }
}
```

## Nginx local mode

```ruby
#/config/puma.rb
[...]
port 3001  # mode tcp
bind "unix:///tmp/nginx.socket" # mode unix socket
[...]
```

```
#/usr/local/etc/nginx/nginx.conf
[...]
http {
    [...]
    upstream app_server {
      # mode tcp
      server          localhost:3001 fail_timeout=0;
      # mode unix
      # server unix:///Users/utilisateur/code/rails/godwd/tmp/sockets/nginx.socket fail_timeout=0;
    }
    [...]
    server {

      listen 8080;
      [...]
      location / {
        [...]
        proxy_pass http://app_server; # same port as Puma
      }
}
```

To use tcp connection between Nginx and Puma, use `foreman start -f Procfile_nginx_port`; it calls 'config.puma_port.rb'.

For unix socket connection, use `foreman start -f Procfile_nginx_socket` (calls 'config/puma_socket.rb')

Navigate to http://localhost:8080/... and you should see 'server: nginx'

> check nginx with `ps aux | grep nginx``

mauris_tovar mariana

# Kill

'<PID>' = `lsof -i :5432` to see how is running at 5432, then `kill -9 <PID>`, or `kill -9 $(lsof -i :5432)`.

- `which psql` and `pg_isready`
