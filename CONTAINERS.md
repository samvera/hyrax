Hyrax-in-a-Container
====================

We're experimentally supporting a number of container environments for Hyrax.
While our goal is to provide a practical, reusable 'reference environment' for
applications, this support is in early stages. If you use these containers, plan
to get your hands dirty.

## Engine Development

We suport a `docker-compose`-based development environment for folks working on
the Hyrax engine. This environment is substantially more like a Hyrax production
setup than the older `fedora_wrapper`/`solr_wrapper` approach.

Start the development setup with:

```sh
docker-compose build
docker-compose up
```

This starts containers for:

  - a `hyrax` test application (`.dassie`);
  - Fedora
  - Solr
  - Postgresql
  - Redis
  - Memcached

It also runs database migrations.

## Hyrax Image

We also provide a base image which can be reused for Hyrax applications: `hyrax`.

```sh
echo "FROM hyrax" > Dockerfile
```

### Maintaining

At the moment, we don't publish hyrax images anywhere (TODO). If you want to use them, you need to build them yourself:

```sh
# build an image for an app using Postgresql (`gem 'pg'`)
docker build --target hyrax --tag hyrax .

# or; build a development image with sqlite
docker build --target hyrax --tag hyrax-sqlite --build-arg DATABASE_APK_PACKAGE="sqlite" .
```
