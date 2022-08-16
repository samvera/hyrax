# nurax-pg

This is an application used for testing the state of [Hyrax](https://github.com/samvera/hyrax)
using Postgres as the metadata store for objects.  In this application, Fedora is
not used for storing object metadata or files. The Hyrax gem is pinned to the
`main` branch to ensure it has the latest possible code for testing.

## Known Issues

Collection model
* `/app/models/collection.rb` - is_a `ActiveFedora::Base`
* if `Collection` is changed to `Valkyrie::Resource`, there is an infinite loop while loading due to reference to ::Collection in `lib/hyrax/collection_name.rb` in the hyrax engine

Default Admin Set
* creating an admin set as a `Valkyrie::Resource` fails to save ACLs.  This is a known issue in Hyrax.  See [Hyrax Issue #5108](https://github.com/samvera/hyrax/issues/5108).

## Questions

Please direct questions about this code or the servers where it runs to the `#nurax` channel on Samvera slack.

## Contributing

If you're working on a PR for this project, create a feature branch off of `main`.

This repository follows the [Samvera Community Code of Conduct](https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/Code+of+Conduct) and [language recommendations](https://github.com/samvera/maintenance/blob/master/templates/CONTRIBUTING.md#language).  Please ***do not*** create a branch called `master` for this repository or as part of your pull request; the branch will either need to be removed or renamed before it can be considered for inclusion in the code base and history of this repository.

## Running Locally

There are two ways to run locally, with Docker or with the rails server.  For both, the first step is to get the repository from GitHub.

```
git clone https://github.com/samvera-labs/nurax-pg.git
```

### Docker

Execute the following commands from the application root to start the app using Docker.

```
docker-compose build
docker-compose up
```

You can find help with additional commands in Hyrax' [FAQ-for-Dassie-Docker-Test-App](https://github.com/samvera/hyrax/wiki/FAQ-for-Dassie-Docker-Test-App).  Most commands can be used directly as described in the FAQ.  A few might require a slight adjustment to work with nurax-pg as a Docker app. 

### Rails Server

Copy `/.env.example` to `/.env` and update as needed (e.g. passwords).

If you want to run directly, there are several services that need to be running on your machine.
* redis
* solr (use same core name as set in `/.env`) _NOTE: nurax-pg is configured to use Solr 7.1 in `/.solr_wrapper.yml`) 
* postgres (use same database name and user role as set in `.env`) _NOTE: You will need to create the database and role using `psql postgres` CLI if they don't already exist._

_NOTE: You can use solr_wrapper to start solr.  You will start redis and postgres using their CLI commands._

To start solr, execute the following command from the application root:

```
bundle exec solr_wrapper -d solr/conf/ nurax-pg -i -p 8987"
```

## Deployment

The application is set up to deploy to DCE infrastructure ([nurax-pg.curationexperts.com](https://nurax-pg.curationexperts.com)) using Capistrano.

Currently, DCE staff and Hyrax working group members should have their github ssh keys added to the server to enable them to deploy.

You can deploy to the "production" instance (currently the only instance) using `bundle exec cap prod deploy`. This defaults to deploying the main branch. If you want to deploy a different branch, you can set it using the environment variable `BRANCH`, e.g. `BRANCH=MY_BRANCHNAME bundle exec cap prod deploy`.
