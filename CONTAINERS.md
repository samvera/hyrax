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

It also runs database migrations.  This will also bring up a development application on `http://localhost:3000`.

### Tasks on Development Environment

In the engine development `app` container, the `.dassie` test Hyrax-based application is setup as a docker
bind mount to `/app/samvera/hyrax-webapp`, and your local development copy of Hyrax (eg. the clone [samvera/hyrax](https://github.com/samvera/hyrax)) is bound to
`/app/samvera/hyrax-engine`.  Those directories are defined as part of the [Dockerfile](Dockerfile) configuration.

What does this structure mean? Let's look at an example.  The following command will list the rake tasks for the Hyrax-based application running in Docker:

```sh
docker-compose exec -w /app/samvera/hyrax-webapp app sh -c "bundle exec rake -T"
```

And this command lists the rake tasks for the Hyrax engine that is in Docker:

```sh
docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rake -T"
```

_**Note**: The `/app/samvera/hyrax-webapp` is analogous to the `.internal_test_app` that we generate as part of the Hyrax engine Continuous Integation._

You should now be able to run `rspec` with the following:

```sh
docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec"
```

Again, notice that we're running `rspec` on `hyrax-engine` (e.g. the Hyrax engine).

In the engine development `app` container, the `.dassie` test application is setup as a docker
bind mount to `/app/samvera/hyrax-webapp`, and your local development copy of Hyrax is bound to
`/app/samvera/hyrax-engine`.

This should bring up a development application on `http://localhost:3000`.

You should now also be able to run `rspec` with:

```sh
docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec"
```

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

## Helm Chart

Also under development is a Helm chart, which we are developing into a robust,
configurable production environment for Hyrax applications.

If you have a Kubernetes cluster configured (`kubectl cluster-info`), you can
deploy the `dassie` test applications with:

```sh
helm dependency update chart/hyrax
helm install -n hyrax --set image.tag=(git rev-parse HEAD) dassie chart/hyrax
```

[dockerhub-samveralabs]: https://hub.docker.com/r/samveralabs
