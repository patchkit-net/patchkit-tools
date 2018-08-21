FROM debian:8.9

RUN apt-get update && apt-get install -y \
    wget \
    libjemalloc-dev \
    gcc \
    make \
    automake \
    autoconf \
    git \
    gcc \
    libtool \
    libpng-dev \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    curl \
    zip

RUN wget https://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.9.tar.gz -O ruby.tar.gz && \
    tar xvzf ruby.tar.gz && \
    rm -f ruby.tar.gz

WORKDIR /ruby-2.1.9

RUN ./configure --with-jemalloc && \
    make -j 2 && \
    make install && \
    rm -rf /ruby-2.1.9

# Install bundler
RUN gem install bundler rb-readline

RUN mkdir -p /workdir
WORKDIR /workdir

ADD Gemfile /workdir/
ADD Gemfile.lock /workdir/

# Copy new Gemfile and Gemfile.lock to update the dependencies
RUN bundle install