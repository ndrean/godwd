# README

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

- Etag will render 304 Not modified response if request is `fresh_when(@variable)`

- set HTTP Cache-Control header: `expires_in 2.hours, public: true`
  <https://api.rubyonrails.org/classes/ActionController/ConditionalGet.html#method-i-expires_in>
  <https://devcenter.heroku.com/articles/http-caching-ruby-rails#conditional-cache-headers>

-`if stale?` : no pb with browser cache here with the API: renders 'Completed 304 Not Modified in 33ms' or querries again when necessary.
Raed <https://thoughtbot.com/blog/take-control-of-your-http-caching-in-rails>

<https://www.synbioz.com/blog/tech/du-cache-http-avec-les-etag-en-rails>
<https://blog.bigbinary.com/2016/03/08/rails-5-switches-from-strong-etags-to-weak-tags.html?utm_source=rubyweekly&utm_medium=email>

# VPS for Rails

<https://mydigital-life.online/comment-installer-rails-sur-un-vps/>
