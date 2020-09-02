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

We also provide a base image which can be reused for your Hyrax applications: `hyrax`.

```sh
echo "FROM samveralabs/hyrax" > Dockerfile
```

_This is for applications that mount Hyrax and is separate from the docker containers for Hyrax engine development._

### Maintaining

We publish several Hyrax images to hub.docker.com under the
[`samveralabs` group][dockerhub-samveralabs]. To build them, do:

```sh
# build an image for an app using Postgresql (`gem 'pg'`)
docker build --target hyrax --tag samveralabs/hyrax:(git rev-parse HEAD) .
docker push samveralabs/hyrax:(git rev-parse HEAD)

# or; build a development image with sqlite
docker build --target hyrax --tag samveralabs/hyrax:(git rev-parse HEAD)-sqlite --build-arg DATABASE_APK_PACKAGE="sqlite" .
docker push samveralabs/hyrax:(git rev-parse HEAD)-sqlite
```

We also publish an image for the stable test application `dassie`:

```sh
docker build --target hyrax-engine-dev --tag samveralabs/dassie:(git rev-parse HEAD) .

docker tag samveralabs/dassie:(git rev-parse HEAD) samveralabs/dassie:$HYRAX_VERSION

docker push samveralabs/dassie:(git rev-parse HEAD)
docker push samveralabs/dassie:$HYRAX_VERSION
```

[dockerhub-samveralabs]: https://hub.docker.com/r/samveralabs
