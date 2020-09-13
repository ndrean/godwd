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

With `ActiveJob` and/or directly `Sidekiq`:

## Sidekiq setup

Added `/config/sidekiq.rb` with `Redis`.
<https://enmanuelmedina.com/en/posts/rails-sidekiq-heroku>

## Mail

We define a class (`EventMailer` and `UserMailer`, both inheriting from `ApplicationMailer`) with actions that will be used by the controller. Each method uses a `html.erb` view to be delivered via the mail protocole `smtp`. The views use the instance variables defined in the actions.

The mails are queued in a Redis db, and Sidekiq is used as the async framework.

The usage of Redis is declared in the '/app/config/initializers/sidekiq.rb' and the gem 'redis'.
For Heroku, we need to set the config vars REDIS_PROVIDER and REDIS_URL.

## Cloudinary remove with Sidekiq

<https://cloudinary.com/documentation/rails_integration#rails_getting_started_guide>

Addded `/config/cloudinary.yml` with `.env`. For Heroku, add 'config.vars'.

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

We could also use ActiveJob (cf mails) by defining a class inheriting from `ApplicationJob` and specifying the 'queue' and use `deliver_later`. Here, we use the Cloudinary method `destroy':
<https://cloudinary.com/documentation/image_upload_api_reference#destroy_method>

```
# /app/jobs/remove_direct_link.rb
class RemoveDirectLink < ApplicationJob
  queue_as :default

  def perform(event_publicID)
    return if !event_publicID
    Cloudinary::Uploader.destroy(event_publicID)
  end
end
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
redis: redis-server --port 6379
```

# Compression

<https://pawelurbanek.com/rails-gzip-brotli-compression>

```
#/config.application.rb
  config.middleware.use Rack::Deflater
```
