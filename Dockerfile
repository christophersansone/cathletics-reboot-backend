FROM ruby:3.4.8
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update -qq && apt-get upgrade -qq
RUN apt-get install -y build-essential libpq-dev libicu-dev #ntp

# configure Rails
ENV APP_HOME /usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# use a common volume for Bundler to prevent a full bundle install every build
ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile BUNDLE_JOBS=2 BUNDLE_PATH=/usr/src/bundle

# Install the version of Bundler compatible with the version of Rails used
#RUN gem install bundler:1.17.3

# Assume the gems will be installed later (and allow for specifying a volume to persist the bundle)
#ADD Gemfile* $APP_HOME/
#RUN bundle install

# Assume the app will be added as a volume
#ADD . $APP_HOME

# install from nodesource using apt-get
RUN apt-get install -y curl
RUN apt-get update
