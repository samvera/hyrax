Hyrax-in-a-Container
====================

Our goal is to provide a practical, reusable reference environment for applications.  The first step is providing an on-ramp for Hyrax engine development. Then providing help with Hyrax-based application development. Finally, providing better guidance around deployment.

The [Hyrax Engine Development](#hyrax-engine-development) is further along than the [Docker Image for Hyrax-based Applications](#docker-image-for-hyrax-based-applications) which is further along than [Deploying to Production](#deploying-to-production).

There are three options for development environments to run:

- [Dassie](#dassie-internal-test-app-with-activefedora) is the default internal test app that will run an ActiveFedora-based Hyrax web application using Fedora 4 as the backend storage. See [Troubleshooting Dassie](#troubleshooting-dassie) if you encounter any issues.
- [Koppie](#koppie-internal-test-app-with-valkyrie-connector-to-postgres) is a newer internal test app that is a Valkyrie-based Hyrax web application that runs with PostGres as backend storage. It does not run ActiveFedora or use Fedora 4. See [Troubleshooting Koppie](#troubleshooting-koppie) if you encounter any issues.
- [Sirenia](#sirenia-internal-test-app-with-valkyrie-connector-to-fedora) is Koppie but with Valkyrie configured to use Fedora 6 metadata and storage adapters.

<!-- NOTE: This title is referenced in the top-level README.md. Keep that in mind if you change it. -->
## Hyrax Engine Development

We support a `docker compose`-based development environment for folks working on
the Hyrax engine. This environment is substantially more like a Hyrax production
setup than the older `fedora_wrapper`/`solr_wrapper` approach.

First, make sure you have installed [Docker](https://www.docker.com/).  Then clone [the Hyrax repository](https://github.com/samvera/hyrax).

### Dassie internal test app with ActiveFedora

Within your cloned repository, tell Docker to get started installing your development environment:

```sh
docker compose build
docker compose up
```

This starts containers for:

  - a `hyrax` test application (`.dassie`);
  - Fedora
  - Solr
  - Postgresql
  - Redis
  - Memcached
  - SideKiq (for background jobs)
  - Chrome (for feature tests)

It also runs database migrations. This will also bring up a development application on `http://localhost:3000`.

To stop the containers for the Hyrax-based application, type <kbd>Ctrl</kbd>+<kbd>c</kbd>. To restart the containers you need only run `docker compose up`.

_**Note:** Starting and stopping Docker in this way will preserve your data between restarts._

#### Code Changes and Testing

With `docker compose up` running, any changes you make to your cloned Hyrax code-base should show up in `http://localhost:3000`; There may be cases where you need to restart your test application (e.g. stop the containers and start them up again).

Any changes you make to Hyrax should be tested. You can run the full test suite using the following command:

```sh
docker compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec"
```

Let's break down the above command:

<dl>
<dt><code>docker compose exec</code></dt>
<dd>Tell docker to run the following:</dd>
<dt><code>-w /app/samvera/hyrax-engine</code></dt>
<dd>In the working directory "/app/samvera/hyrax-engine" (e.g. your cloned Hyrax repository)</dd>
<dt><code>app</code></dt>
<dd>of the container named "app"</dd>
<dt><code>sh -c</code>
<dd>run the following shell script</dd>
<dt><code>"bundle exec rspec"</code></dt>
<dd>run the rspec test suite</dd>
</dl>

_**Note:**_ The `bundle exec rspec` portion of the command runs the whole test suite. See the [rspec command documentation](https://github.com/rspec/rspec-core#the-rspec-command) for how to refine your test runs.

#### The Docker Container Named "app"

As a developer, you may need to run commands against the Hyrax-based application and/or the Hyrax engine.  Examples
of those commands are `rails db:migrate` and `rspec`.  You would run `rails db:migrate` on the Hyrax-based
application, and `rspec` on the Hyrax engine.

In the engine development `app` container, the `.dassie` test Hyrax-based application is setup as a docker
bind mount to `/app/samvera/hyrax-webapp`, and your local development copy of Hyrax (eg. the clone [samvera/hyrax](https://github.com/samvera/hyrax)) is bound to
`/app/samvera/hyrax-engine`.  Those directories are defined as part of the [Dockerfile](Dockerfile) configuration.
                                                                                                                                 .
What does this structure mean? Let's look at an example. The following command will list the rake tasks for the Hyrax-based application running in Docker:

```sh
docker compose exec -w /app/samvera/hyrax-webapp app sh -c "bundle exec rake -T"
```

And this command lists the rake tasks for the Hyrax engine that is in Docker:

```sh
docker compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rake -T"
```

In the two examples, note the difference in the `-w` switch. In the first case, it's referencing the Hyrax-based application. In the latter case, it's referencing the Hyrax engine.

#### Debugging

If you are interested in running Hyrax in debug mode, this requires a somewhat different approach than running Hyrax bare-metal.  You need to use `docker attach` to debug the running docker instance.

1. With `docker compose up` running open a new Terminal session.
2. In that new Terminal session, using `docker container ls` find the "CONTAINER ID" for the `hyrax-engine-dev`.
3. With the "CONTAINER ID", run `docker attach <CONTAINER ID>`.

This advice comes from [Debugging Rails App With Docker Compose: How to use Byebug in a dockerized rails app](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4).

#### Troubleshooting Dassie

##### Bad Address SOLR

With `docker compose up` running, if you see the following, then there may be issues with file permissions:

```
db_migrate_1  | waiting for solr:8983
db_migrate_1  | nc: bad address 'solr'
```

Check the Docker application logs and look for permission errors:

```
Executing /opt/docker-solr/scripts/precreate-core hyrax_test /opt/solr/server/configsets/hyraxconf
cp: cannot create directory '/var/solr/data/hyrax_test': Permission denied
```

The solution that appears to work is to `docker compose down --volumes`; This will tear down the docker instance, and remove the volumes.  You can then run `docker compose up` to get back to work.  _**Note:** the `--volumes` switch will remove all custom data._

##### Errors building the Docker image

If you encounter errors running `docker compose build`, try running `bundle update` in `./hyrax` as well as within `./hyrax/.dassie`. That can help clear up the problem of a failure to build a particular gem.

##### Containers do not all start

If any of the services fail to start on `docker compose up`, try clearing out any `Gemfile.lock` files that might exist in `./hyrax` or `./hyrax/.dassie` and run `docker compose build` again, then `docker compose up` again.

### Koppie Internal Test App with Valkyrie Connector to Postgres

Build docker images for Koppie: `docker compose -f docker-compose-koppie.yml build`

Start Koppie: `docker compose -f docker-compose-koppie.yml up`

This starts containers for:

  - a `hyrax` test application (`.koppie`);
  - Solr
  - Postgresql
  - Redis
  - Memcached
  - SideKiq (for background jobs)
  - Chrome (for feature tests)

It also runs database migrations. This will also bring up a development application on `http://localhost:3001`.

To stop the containers for the Hyrax-based application, type <kbd>Ctrl</kbd>+<kbd>c</kbd>. To restart the containers run `docker compose -f docker-compose-koppie.yml up`.

_**Note:** Starting and stopping Docker in this way will preserve your data between restarts._

Koppie runs as a different project than Dassie, so it should be possible to run both concurrently (assuming your workstation has enough RAM).

#### Run rails console on Koppie

Currently Koppie should not be used for running specs. See [Code Changes and Testing](#code-changes-and-testing) under Dassie instead until the specs can be updated for a valkyrie only environment.

```sh
docker compose -f docker-compose-koppie.yml up
docker compose -f docker-compose-koppie.yml exec app bundle exec rails c
```
#### Troubleshooting Koppie

If the postgres service logs show permissions errors, there may be old data from alternate versions of the postgres image. The old data volumes can deleted by using `docker compose -f docker-compose-koppie.yml down -v`

Errors such as `exec /app/samvera/hyrax-entrypoint.sh: no such file or directory` in the app, sidekiq and db_migrate services may indicate an outdated cached hyrax-base image layer was used to build the koppie image. Try `docker compose -f docker-compose-koppie.yml build --no-cache`  to rebuild all the image layers.

It was also seen on a Windows 10 host and was resolved by using the git `--core.autocrlf` option when cloning the repo.

<!-- NOTE: This title is referenced in the top-level documentation/developing-your-hyrax-based-app.md. Keep that in mind if you change it. -->
## Docker Image for Hyrax-based Applications

We also provide a base image which can be reused for your Hyrax applications: `hyrax`.

```sh
echo "FROM samveralabs/hyrax" > Dockerfile
```

_This is for applications that mount Hyrax and is separate from the docker containers for Hyrax engine development._

### Sirenia Internal Test App with Valkyrie Connector to Fedora

Sirenia uses the same image as koppie. If you have not already done so, follow the build instructions for koppie above.

Start Sirenia: `docker compose -f docker-compose-sirenia.yml up`

This starts containers for:

  - a `hyrax` test application (`.sirenia`);
  - Fedora
  - Solr
  - Postgresql
  - Redis
  - Memcached
  - SideKiq (for background jobs)
  - Chrome (for feature tests)

It also runs database migrations. This will also bring up a development application on `http://localhost:3002`.

To stop the containers for the Hyrax-based application, type <kbd>Ctrl</kbd>+<kbd>c</kbd>. To restart the containers run `docker compose -f docker-compose-sirenia.yml up`.

_**Note:** Starting and stopping Docker in this way will preserve your data between restarts._

Sirenia runs as a different project than Dassie and Koppie, so it should be possible to run both concurrently (assuming your workstation has enough RAM).

#### Run rails console on Sirenia

Currently Sirenia should not be used for running specs. See [Code Changes and Testing](#code-changes-and-testing) under Dassie instead until the specs can be updated for a valkyrie only environment.

```sh
docker compose -f docker-compose-sirenia.yml up
docker compose -f docker-compose-sirenia.yml exec app bundle exec rails c
```

### Maintaining

We publish several Hyrax images to the [GitHub container registry][ghcr] under
the [Samvera organization][samvera-packages].  To build them:

```sh
export HYRAX_VERSION=v5.0.0 # or desired version
git checkout hyrax-$HYRAX_VERSION

docker build --target hyrax-base --tag ghcr.io/samvera/hyrax/hyrax-base:$(git rev-parse HEAD) .

docker tag ghcr.io/samvera/hyrax/hyrax-base:$(git rev-parse HEAD) ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_VERSION

docker push ghcr.io/samvera/hyrax/hyrax-base:$(git rev-parse HEAD)
docker push ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_VERSION
```

Do the same for `hyrax-worker-base`.

We also publish an image for the stable test application `dassie`:

```sh
docker build --target hyrax-engine-dev --tag ghcr.io/samvera/hyrax/dassie:$(git rev-parse HEAD) .

docker tag ghcr.io/samvera/hyrax/dassie:$(git rev-parse HEAD) ghcr.io/samvera/hyrax/dassie:$HYRAX_VERSION

docker push ghcr.io/samvera/hyrax/dassie:$(git rev-parse HEAD)
docker push ghcr.io/samvera/hyrax/dassie:$HYRAX_VERSION
```

## Deploying to Production

Also under development is a Helm chart, which we are developing into a robust,
configurable production environment for Hyrax applications.

If you have a Kubernetes cluster configured (`kubectl cluster-info`), you can
deploy the `dassie` test applications with:

```sh
helm dependency update chart/hyrax
helm install -n hyrax --set image.tag=(git rev-parse HEAD) dassie chart/hyrax
```

[ghcr]: https://docs.github.com/en/enterprise-cloud@latest/packages/working-with-a-github-packages-registry/working-with-the-container-registry
[samvera-packages]: https://github.com/orgs/samvera/packages
