# Oregon Digital Analytics
----
## Table of Contents
  * [Running the stack](#running-the-stack)
    * [Important URL's](#important-urls)
    * [Install Docker](#install-docker)
    * [Start the server](#start-the-server)
    * [Admin User](#admin-user)
    * [Access the container](#access-the-container)
      * [Seed the database](#seed-the-database)
      * [Run migrations](#run-migrations)
      * [Access the rails Console](#access-the-rails-console)
    * [Rubocop](#rubocop)
    * [RSpec](#rspec)
    * [Rubocop](#rubocop)
    * [Stop the app and services](#stop-the-app-and-services)
    * [Troubleshooting](#troubleshooting)
----

## Running the stack
### Important URL's
- Local site: localhost:3000
- Staging sites:
  - With Google Analytics:
  - With Matomo:
- Production site:
- Solr:
- Sidekiq:


### If this is your first time working in this repo or the Dockerfile has been updated you will need to update your services first
  ```bash
  sc build -s app
  ```

### Start the server
```bash
sc up -s app
```
This command starts the web container, allowing Rails to be started or stopped independent of the other services. Once that starts (you'll see the line `Listening on tcp://0.0.0.0:3000` to indicate a successful boot), you can view your app at the [dev URL](#important-urls) above.

### Admin User
- Local:
  - email: admin@example.com
  - password: admin_password
- Staging:
  - email:
  - password:

### Access the container
- In a separate terminal window or tab than the running server, run:
  ``` bash
  docker-compose exec app sh
  ```

- You must be inside the container to:
  #### Seed the database
  ``` bash
  rails db:seed
  ```

  #### Run migrations
  ``` bash
  rails db:migrate
  ```

  #### Access the rails console
  ``` bash
  rails c
  ```

### Rubocop
(The [`-a` flag](https://docs.rubocop.org/rubocop/usage/basic_usage.html#auto-correcting-offenses) is optional)

```bash
docker-compose exec -w /app/samvera/hyrax-engine app sh
rubocop -a # all files
rubocop -a path/to/file.rb # one file
```

### RSpec
Run rspec in a separate terminal window or tab than the running server.
Learn about [general rspec commands here](https://github.com/rspec/rspec-rails/tree/4-1-maintenance#running-specs).
Learn about rspec commands for a [Dassie app here](https://github.com/samvera/hyrax/wiki/FAQ-for-Dassie-Docker-Test-App#how-do-i-run-tests).

All tests:
  ``` bash
  docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec"
  ```

One spec file:
  ``` bash
  docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec spec/path/to/spec.rb"
  ```

One test in one spec file:
  ``` bash
  docker-compose exec -w /app/samvera/hyrax-engine app sh -c "bundle exec rspec spec/path/to/spec.rb:18"
  ```

### Stop the app and services
- Press `Ctrl + C` in the window where `sc up -s app` is running
- When that's done `sc stop` shuts down the running containers
- Optional:
  - `dc down` will stop your containers, remove those containers and remove networks that were created
  - `dc down -v` will stop your containers, remove those containers, remove networks that were created and remove volumes

### Troubleshooting
- Was the Dockerfile changed on your most recent `git pull`? Refer to the instructions above.
