# README

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

If set to `:sql` then the schema is in `db/structure.sql` and run:

```bash
rails db:schema:load
rails db:seed
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

Added `/config/sidekiq.rb` with `Redis`.
<https://github.com/mperham/sidekiq/wiki>
<https://enmanuelmedina.com/en/posts/rails-sidekiq-heroku>

The sidekiq console is available at http://localhost:3001/sidekiq since a route is defined:

```ruby
mount Sidekiq::Web => '/sidekiq'
```

## Mail

We define a class (`EventMailer` and `UserMailer`, both inheriting from `ApplicationMailer`) with actions that will be used by the controller. Each method uses a `html.erb` view to be delivered via the mail protocole `smtp`. The views use the instance variables defined in the actions.

The mails are queued in a Redis db, and Sidekiq is used as the async framework.

The usage of Redis is declared in the '/app/config/initializers/sidekiq.rb' and the gem 'redis'.
For Heroku, we need to set the config vars REDIS_PROVIDER and REDIS_URL.

## Cloudinary remove with Sidekiq

<https://cloudinary.com/documentation/rails_integration#rails_getting_started_guide>

<https://github.com/cloudinary/cloudinary_gem>

> credentials: they are passed manually to each call in the method, and added as `config vars` to Heroku. The `/config/cloudinary.yml` is not used since it doesn't accept `.env` variables.

We use `RemoveDirectLink`to async remove a picture from Cloudinary by the Rails backend. We can use activeJob or directly a worker.

Here, we used a worker (without using ActiveJob, just include `Sidekiq::Worker` without `default queue`) and use `perform_async`.

```
 # /App/workers/remove_direct_link.rb
class RemoveDirectLink
  include Sidekiq::Worker

  def perform(event_publicID)
    return if !event_publicID
    Cloudinary::Uploader.destroy(event_publicID)
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

React will run on 'localhost:3000" whilst Rails will run on 'localhost:3001'

```ruby
# /config/puma.rb
port        ENV.fetch("PORT") { 3001 }
```

# CORS

CORS stands for Cross-Origin Resource Sharing, a standard that lets developers specify who can access the assets on a server and what HTTP requests are accepted. For example, a restrictive 'same-origin' policy would prevent your Rails API at localhost:3001 from sending and receiving data to your front-end at localhost:3000.

```ruby
# /config/application.rb
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ‘localhost:3000', 'godownwind.online'
    resource ‘*’, headers: :any, methods: [:get, :post, :options]
  end
end
```

# Redis

```ruby
# .env
REDIS_URL='redis://localhost:6379'

#/config/initializers/sidekiq.rb
...config.redis = { url: ENV['REDIS_URL'], size: 2 }
```

# Procfile

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

<https://pawelurbanek.com/rails-gzip-brotli-compression>

```
#/config.application.rb
  config.middleware.use Rack::Deflater
```

# Arrays in PostgreSQL

<https://stackoverflow.com/questions/63404637/rails-submitting-array-to-postgres>

To accept an array, we need to separate between the ','.

```
if params[:event][:itinary_attributes][:start_gps]
  params[:event][:itinary_attributes][:start_gps] = params[:event][:itinary_attributes][:start_gps][0].split(',')
  params[:event][:itinary_attributes][:end_gps] = params[:event][:itinary_attributes][:end_gps][0].split(',')
end
```

# Running multiple processes

Use `foreman`

The `database.yml` musn't use the key `db` (or set `localhost`)

# Docker

```bash
rm -rf tmp/*
docker rm $(docker ps -q -a) -f
docker rmi $(docker images -q) -f
docker-compose up --build
```

Set the key `host: db` in `database.yml` where `db` is the name of the Postgresql service in `docker-compose.yml`.

```ruby

```

<https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose>

Needs in `.env`:

- Postgres:

```
# .env (Postgres Docker)
POSTGRES_USER=postgres
POTGRES_PASSWORD=postgres
```

- Redis:

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
docker-compose exec web rails db:create
docker-compse exec web rails db:schema:load # instead of db:migrate
docker-compose exec web rails db:seed
```

## docker commands

- list all containers: `docker container ls -a`

- list all containers's ids: `docker container ls -aq`

- stop all containers by passing a list of ids: `docker container stop $(docker container ls -aq)`

- remove all containers by passing a list of ids: `docker container rm $(docker container ls -aq)`

- To wipe Docker clean and start from scratch, enter the command:
  `docker container stop $(docker container ls –aq) && docker system prune –af ––volumes`
