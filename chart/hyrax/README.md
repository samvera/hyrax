Hyrax Helm
==========

This [Helm][helm] chart provides configurable deployments for Hyrax applications
to [Kubernetes][k8s] clusters. It seeks to be a complete but flexible
production-ready setup for Hyrax applications. By default it deploys:

  - A Hyrax-based Rails application
  - Fedora Commons v4.7
  - Postgresql
  - Solr (in a cloud configuration, including Apache Zookeeper)
  - Redis

## A base Hyrax deployment

Because Hyrax is a [Rails Engine][engine]---not a stand-alone application---
deploying it requires us to have a specific application. This chart assumes that
the user has a container image based on `samveralabs/hyrax` (see:
[CONTAINERS.md][containers]) that includes their application. Point the chart at
your image by setting the `image.repository` and `image.tag` values.

By default, the chart deploys [images][dassie-images] for Hyrax's development
application, [`dassie`][dassie].

For application configuration, we take our queues from [12-factor][twelve]
methodology. Applications using environment variables to manage their
configuration can be easily reconfigured across different releases using this
chart; e.g. the same chart can be used to deploy sandbox, staging, and
production environments.

The chart populates the following environment variables:

|-------------------|--------------------------------|------------------------|
| Variable          | Description                    | Condition              |
|-------------------|--------------------------------|------------------------|
| DB_HOST           | Postgresql hostname            | `postgresql.enabled`   |
| DB_PORT           | Postgresql service port        | `postgresql.enabled`   |
| MEMCACHED_HOST    | Memcached host                 | `memcached.enabled`    |
| RACK_ENV          | app environment ('production') | n/a                    |
| RAILS_ENV         | app environment ('production') | n/a                    |
| REDIS_HOST        | Redis service host             | `redis.enabled`        |
| FCREPO_HOST       | Fedora Commons host            | `fcrepo.enabled`       |
| FCREPO_PORT       | Fedora Commons port            | `fcrepo.enabled`       |
| FCREPO_REST_PATH  | Fedora Commons REST endpoint   | `fcrepo.enabled`       |
| SOLR_HOST         | Solr service host              | `solr.enabled`         |
| SOLR_PORT         | Solr service port              | `solr.enabled`         |
| SOLR_URL          | Solr service full URL          | `solr.enabled`         |
|----------------- -|--------------------------------|------------------------|

## For DevOps:

For those interested in trying out or contributing to this Chart, it's helpful
to setup a simple cluster locally. Various projects exist to make this easy; we
recommend [`k3d`][k3d] or [minikube][minikube].

For example, with `k3d`:

```sh
k3d cluster create dev-cluster --api-port 6550 -p 80:80@loadbalancer --agents 3
```

[containers]: ../../CONTAINERS.md#hyrax-image
[dassie]: ../../.dassie/README.md
[dassie-image]: https://hub.docker.com/r/samveralabs/dassie
[engine]: https://guides.rubyonrails.org/engines.html
[helm]: https://helm.sh
[k3d]: https://k3d.io
[k8s]: https://kubernetes.io
[minikube]: https://minikube.sigs.k8s.io/docs/
