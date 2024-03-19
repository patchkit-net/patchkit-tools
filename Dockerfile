FROM ruby:2.4.10-buster

RUN apt-get update && apt-get install -y \
    wget \
    gcc \
    make \
    automake \
    autoconf \
    git \
    gcc \
    libtool \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    curl \
    zip

WORKDIR /workdir

ADD Gemfile /workdir/
ADD Gemfile.lock /workdir/

RUN bundle install