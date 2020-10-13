# we build on top of an already existing image made for running Ruby code from Docker hub
FROM ruby:2.6.6-alpine
# install the required packages inside Docker: PostgreSQL (libpq-dev, postgres-client)
RUN apk update && apk add --update --no-cache --virtual build-dependency build-base bash  git curl ruby-dev postgresql-dev  


ENV RAILS_ROOT var/www/myapp
RUN mkdir -p $RAILS_ROOT 
WORKDIR $RAILS_ROOT
# Setting env up
ENV RAILS_ENV='development'
ENV RACK_ENV='development' 

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

# install the bundler gem. Should match the version in 'Gemfile.lock'
RUN gem install bundler:2.1.4   && \
    bundle install

RUN apk del build-dependency
RUN apk add postgresql-client postgresql-libs tzdata

# COPY entrypoint.sh /usr/bin/
# RUN chmod +x /usr/bin/entrypoint.sh
# ENTRYPOINT ["entrypoint.sh"]

COPY . .

EXPOSE 3001

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"] 
