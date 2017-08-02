FROM ruby:2.4-alpine

## Install Rails Dependencies
RUN apk update && apk add build-base nodejs bash mysql-dev mysql-client sqlite-dev
RUN echo -e 'http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing' > /etc/apk/repositories && \
   apk add --no-cache yarn

ENV RAILS_ENV development

ENV EDITOR vi
ENV INSTALL_PATH /site
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

COPY Gemfile* ./
RUN bundle install --binstubs

COPY . .

RUN bin/rails assets:precompile
RUN bin/rails db:migrate

CMD puma -C config/puma.rb

