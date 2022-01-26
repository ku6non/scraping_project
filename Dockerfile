FROM ruby:3.1.0
RUN apt-get update -qq && apt-get install -y build-essential nodejs
ENV LANG="C.UTF-8" PAKAGES="curl-dev build-base alpine-sdk tzdata sqlite-dev less ruby-dev nodejs"
RUN apt-get install libsqlite3-dev
WORKDIR /yahoo_scraping
COPY ./yahoo_scraping .
RUN bundle install

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
