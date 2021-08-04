Hyrax-in-a-Container
====================

Our goal is to provide a practical, reusable "reference environment for applications.  The first step is providing
on on-ramp for Hyrax engine development.  Then providing help with Hyrax-based application development.  Finally,
providing better guidance around deployment.

Where are we at?  It's complicated.  What we have below is experimental support, but one that we want to push
towards.  We need your help to keep pushing in this direction.  So dig in and prepare to get your hands dirty.

The [Hyrax Engine Development](#hyrax-engine-development) is further along than the [Docker Image for Hyrax-based Applications](#docker-image-for-hyrax-based-applications) which is further along than [Deploying to Production](#deploying-to-production).

<!-- NOTE: This title is referenced in the top-level README.md. Keep that in mind if you change it. -->
## Hyrax Engine Development

We support a `docker-compose`-based development environment for folks working on
the Hyrax engine. This environment is substantially more like a Hyrax production
setup than the older `fedora_wrapper`/`solr_wrapper` approach.

First, make sure you have installed [Docker](https://www.docker.com/).  Then clone [the Hyrax repository](https://github.com/samvera/hyrax).

Within your cloned repository, tell Docker to get started installing your development environment:

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
  - SideKiq (for background jobs)

It also runs database migrations. This will also bring up a development application on `http://localhost:3000`.

To stop the containers for the Hyrax-based application, type <kbd>Ctrl</kbd>+<kbd>c</kbd>. To restart the containers you need only run `docker-compose up`.

_**Note:** Starting and stopping Docker in this way will preserve your data between restarts._

_**Note:** I (Jeremy) encountered a problem using `docker-compose build`. I ran `bundle update` in `./hyrax` as well as within `./hyrax/.dassie`. That appeared to clear up the problem of a failure to build a gem._

### Code Changes and Testing

With `docker-compose up` running, any changes you make to your cloned Hyrax code-base should show up in `http://localhost:3000`; There may be cases where you need to restart your test application (e.g. stop the containers and start them up again).

Any changes you make to Hyrax should be tested. You can run the full test suite using the following command:

```sh
docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec"
```

Let's break down the above command:

<dl>
<dt><code>docker-compose exec</code></dt>
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

_**Note**: The `/app/samvera/hyrax-webapp` is analogous to the `.internal_test_app` that we generate as part of the Hyrax engine Continuous Integration._

### The Docker Container Named "app"

As a developer, you may need to run commands against the Hyrax-based application and/or the Hyrax engine.  Examples
of those commands are `rails db:migrate` and `rspec`.  You would run `rails db:migrate` on the Hyrax-based
application, and `rspec` on the Hyrax engine.

In the engine development `app` container, the `.dassie` test Hyrax-based application is setup as a docker
bind mount to `/app/samvera/hyrax-webapp`, and your local development copy of Hyrax (eg. the clone [samvera/hyrax](https://github.com/samvera/hyrax)) is bound to
`/app/samvera/hyrax-engine`.  Those directories are defined as part of the [Dockerfile](Dockerfile) configuration.
                                                                                                                                 .
What does this structure mean? Let's look at an example. The following command will list the rake tasks for the Hyrax-based application running in Docker:

```sh
docker-compose exec -w /app/samvera/hyrax-webapp app sh -c "bundle exec rake -T"
```

And this command lists the rake tasks for the Hyrax engine that is in Docker:

```sh
docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rake -T"
```

In the two examples, note the difference in the `-w` switch. In the first case, it's referencing the Hyrax-based application. In the latter case, it's referencing the Hyrax engine.

### Debugging

I (Jeremy) find myself wanting to debug the application.  This requires a somewhat different approach than running Hyrax bare-metal.  You need to use `docker attach` to debug the running docker instance.

1. With `docker-compose up` running open a new Terminal session.
2. In that new Terminal session, using `docker container ls` find the "CONTAINER ID" for the `hyrax-engine-dev`.
3. With the "CONTAINER ID", run `docker attach <CONTAINER ID>`.

This advice comes from [Debugging Rails App With Docker Compose: How to use Byebug in a dockerized rails app](https://medium.com/gogox-technology/debugging-rails-app-with-docker-compose-39a3767962f4).

### Troubleshooting

#### Bad Address SOLR

With `docker-compose up` running, if you see the following, then there may be issues with file permissions:

```
db_migrate_1  | waiting for solr:8983
db_migrate_1  | nc: bad address 'solr'
```

Check the Docker application logs and look for permission errors:

```
Executing /opt/docker-solr/scripts/precreate-core hyrax_test /opt/solr/server/configsets/hyraxconf
cp: cannot create directory '/var/solr/data/hyrax_test': Permission denied
```

The solution that appears to work is to `docker-compose down --volumes`; This will tear down the docker instance, and remove the volumes.  You can then run `docker-compose up` to get back to work.  _**Note:** the `--volumes` switch will remove all custom data._

<!-- NOTE: This title is referenced in the top-level documentation/developing-your-hyrax-based-app.md. Keep that in mind if you change it. -->
## Docker Image for Hyrax-based Applications

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

## Deploying to Production

Also under development is a Helm chart, which we are developing into a robust,
configurable production environment for Hyrax applications.

If you have a Kubernetes cluster configured (`kubectl cluster-info`), you can
deploy the `dassie` test applications with:

```sh
helm dependency update chart/hyrax
helm install -n hyrax --set image.tag=(git rev-parse HEAD) dassie chart/hyrax
```

[dockerhub-samveralabs]: https://hub.docker.com/r/samveralabs
