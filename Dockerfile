# we build on top of an already existing image made for running Ruby code from Docker hub
FROM ruby:2.6.6-alpine
# install the required packages inside Docker: PostgreSQL (libpq-dev, postgres-client)
RUN apk update && apk add bash build-base nodejs  postgresql-dev tzdata
#if needed, add yarn
RUN gem install rails bundler --no-document
# create folder called 'project' to host the codebase

RUN mkdir -p /api
# set the wroking directory to 'api' folder
WORKDIR /api
# copy from current directory '.' to the working directory './'
COPY Gemfile /api/Gemfile
COPY Gemfile.lock /api/Gemfile.lock



# install the bundler gem. Should match the version in 'Gemfile.lock'
RUN bundle install --no-binstubs || bundle check
# Note: specific version can be set 'RUN gem install bundler -v 2.1.4'

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# node.js
#RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
#    && apt install -y nodejs
#if yarn and JS

#COPY package.json yarn.lock . ./
#RUN yarn install --check-files

# copy the codebase into Docker
COPY . .

EXPOSE 3001
# set the start command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

#ENTRYPOINT ['./entrypoint.sh']
# chmod +x ./entrypoint.sh