# Koppie

> Isolated granite outcrops in Southern Africa that are a favored habitat for hyraxes.

Koppie is an application used for testing the state of [Hyrax](https://github.com/samvera/hyrax)
using Postgres as the metadata store for objects.  This is similar to the Dassie test application
that lives in `.dassie`, however in this application Fedora is
not used for storing object metadata or files. The Hyrax gem is sourced from the local hyrax
directory one level up from `.koppie` for development purposes.

## Known Issues

Collection model
* `/app/models/collection.rb` - is_a `ActiveFedora::Base`
* if `Collection` is changed to `Valkyrie::Resource`, there is an infinite loop while loading
  due to reference to ::Collection in `lib/hyrax/collection_name.rb` in the hyrax engine

Default Admin Set
* creating an admin set as a `Valkyrie::Resource` fails to save ACLs.  This is a known issue in Hyrax.
  See [Hyrax Issue #5108](https://github.com/samvera/hyrax/issues/5108).

## Questions

Please direct questions about this code or the servers where it runs to the `#hyrax-valkyrie`
channel on Samvera slack.

## Contributing

If you're working on a PR for this project, create a feature branch off of `main`.

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct)
and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).
Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will
either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Running Locally

There are two ways to run locally, with Docker or with the rails server.  For both, the first step is to get the repository from GitHub.

```
git clone https://github.com/samvera/hyrax.git
```

### Docker

Execute the following commands from the hyrax root to start the app using Docker.

```
docker compose -f docker-compose-koppie.yml build
docker compose -f docker-compose-koppie.yml up
```

You can find help with additional commands in Hyrax' [FAQ-for-Dassie-Docker-Test-App](https://github.com/samvera/hyrax/wiki/FAQ-for-Dassie-Docker-Test-App).
Most commands can be used directly as described in the FAQ.  A few might require
a slight adjustment to work with koppie as a Docker app.
