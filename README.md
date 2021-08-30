# This is the Oregon Digital Analytics for Hyrax project page

Here you will find information about the project, the issue board, and code.

We will be working to implement some of the work from the Hyrax Analytics Working Group (HAWG).  We want to thank everyone who participated in that working group for all of their effort and for the users stories, use cases, mockups, and priorities thay created. Information about the group as well as the artifacts from their works can be found at https://wiki.lyrasis.org/pages/viewpage.action?pageId=87461330

## Contacts:

For questions on this project please contact:
- Franny Gaede  - mfgaede@uoregon.edu
- Margaret Mellinger - margaret.mellinger@oregonstate.edu
- Kevin Kochanski - kevin@notch8.com
- Crystal Richardson - crystal@notch8.com

![Samvera's Hyrax Logo](https://raw.githubusercontent.com/samvera/hyrax/gh-pages/assets/images/hyrax_logo_horizontal_white_background.png)

Code: [![Version](https://badge.fury.io/rb/hyrax.png)](http://badge.fury.io/rb/hyrax)
[![CircleCI](https://circleci.com/gh/samvera/hyrax.svg?style=svg)](https://circleci.com/gh/samvera/hyrax)
[![Code Climate](https://codeclimate.com/github/samvera/hyrax/badges/gpa.svg)](https://codeclimate.com/github/samvera/hyrax)

Docs: [![Documentation Status](https://inch-ci.org/github/samvera/hyrax.svg?branch=master)](https://inch-ci.org/github/samvera/hyrax)
[![API Docs](http://img.shields.io/badge/API-docs-blue.svg)](http://rubydoc.info/gems/hyrax)
[![Contribution Guidelines](http://img.shields.io/badge/CONTRIBUTING-Guidelines-blue.svg)](./.github/CONTRIBUTING.md)
[![Apache 2.0 License](http://img.shields.io/badge/APACHE2-license-blue.svg)](./LICENSE)

Jump in: [![Slack Status](http://slack.samvera.org/badge.svg)](http://slack.samvera.org/)

## Table of Contents

* [What is Hyrax?](#what-is-hyrax)
* [Feature Documentation](#feature-documentation)
* [Support Policies](#support-policies)
* [Help](#help)
* [Working with Hyrax](#working-with-hyrax)
  * [Developing the Hyrax Engine](#developing-the-hyrax-engine)
    * [Contributing](#contributing)
    * [Release process](#release-process)
  * [Developing your Hyrax\-based Application](#developing-your-hyrax-based-application)
  * [Deploying your Hyrax\-based Application to production](#deploying-your-hyrax-based-application-to-production)
* [Acknowledgments](#acknowledgments)
* [License](#license)
* [Docker development setup](#docker-development-setup)
* [Deploy a new release](#deploy-a-new-release)

<aside>Table of contents created by <a href="https://github.com/ekalinin/github-markdown-toc.go">gh-md-toc</a></aside>

## What is Hyrax?

Hyrax is a [Ruby on Rails Engine](https://guides.rubyonrails.org/engines.html) built by the [Samvera community](https://samvera.org). Hyrax provides a foundation for creating many different digital repository applications.

_**Note:** As a Rails Engine, Hyrax is not a web application. To build your digital repository using Hyrax you must mount the Hyrax engine within a Rails application. We call an application that mounts Hyrax a "Hyrax-based application" (or sometimes a "Hyrax Application")._

Hyrax offers the ability to:

* Create repository object types on demand
* Deposit content via multiple configurable workflows
* Describe content with flexible metadata
* Enable/disable optional features via an administrative dashboard
* And more (https://hyrax.samvera.org/about/)

## Feature Documentation

* List of features: [Feature Matrix](https://github.com/samvera/hyrax/wiki/Feature-matrix)
* Configuration and enabling features: [Hyrax Management Guide](https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide)
* Walk-through on using features: [Hyrax Feature Guides](https://samvera.github.io/intro-to.html)
* [Entity Relationship Diagram](./artifacts/entity-relationship-diagram.pdf)
* For general information about Hyrax: [Hyrax Site](https://hyrax.samvera.org/)
* A note about [versions of Hyrax](./documentation/note-about-versions.md)

## Support Policies

* Hyrax 3.x supports the latest browser versions for Chrome, Firefox, Edge, and Safari.

## Help

The Samvera community is here to help. Please see our [support guide](./.github/SUPPORT.md).

## Working with Hyrax

There are two primary Hyrax development concerns:

1. Developing the Hyrax engine
2. Developing your Hyrax-based Application

### Developing the Hyrax Engine

This is where you work on the code-base that will be used by yours and other Hyrax-based applications.  We recommend using [Docker and Hyrax's engine development containers](./CONTAINERS.md).

<aside>
    <p><em><strong>Note:</em></strong> This is not the only path for Hyrax-engine development.  In the past, <a href="./documentation/legacyREADME.md">we documented extensive steps</a> to install the various dependencies for Hyrax-engine development. There is also a <a href="https://github.com/samvera/hyrax/wiki/Hyrax-Development-Guide#quick-start-for-hyrax-development">Quick Start for Hyrax engine development</a> that outlines steps for working on the Hyrax engine.</p>
    <p>By moving to Docker, we are encoding the documentation steps for standing up a Hyrax-engine development environment.</p>
</aside>

#### Contributing

We'd love to accept your contributions.  Please see our guide to [contributing to Hyrax](./.github/CONTRIBUTING.md).

Here are possible ways to help:

* The Hyrax user interface is translated into a number of languages, and many of these translations come from Google Translate. If you are a native or fluent speaker of a non-English language, your help improving these translations are most welcome. (Hyrax currently supports English, Spanish, Chinese, Italian, German, French, and Portuguese.)
  * Do you see English in the application where you would expect to see one of the languages above? If so, [file an issue](https://github.com/samvera/hyrax/issues/new) and suggest a translation, please.
* [Contribute a user story](https://github.com/samvera/hyrax/issues/new).
* Help us improve [Hyrax's test coverage](https://coveralls.io/r/samvera/hyrax) or [documentation coverage](https://inch-ci.org/github/samvera/hyrax).
* Refactor away [code smells](https://codeclimate.com/github/samvera/hyrax).

#### Release process

See the [release management process](https://github.com/samvera/hyrax/wiki/Release-management-process).

### Developing your Hyrax-based Application

For those familiar with Rails, this is where you create your own application (via `rails new`) and add Hyrax as a gem to your `Gemfile`.  Your Hyrax-based application is the place for you to create features specific to your Hyrax-based application.

For more information, see [our documentation on developing your Hyrax-based application](./documentation/developing-your-hyrax-based-app.md).

### Deploying your Hyrax-based Application to production

Steps to deploy a Hyrax-based application to production will vary depending on your particular ecosystem but here are some methods and things to consider:

 * [Samvera Community Knowledge Base: Running in Production](https://samvera.github.io/service-stack.html)
 * [Helm Chart](./CONTAINERS.md#deploying-to-production) (for cloud-based Kubernetes-style deployments)

## Acknowledgments

This software has been developed by and is brought to you by the Samvera community.  Learn more at the
[Samvera website](http://samvera.org/).

![Samvera Logo](https://wiki.lyrasis.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

## License

Hyrax is available under [the Apache 2.0 license](LICENSE).

## Docker development setup
#### Refer to [Repo-README](./Repo-README.md) for repository specific instructions

1) Install Docker.app

2) gem install stack_car

3) We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

4) sc up

``` bash
gem install stack_car
sc up --service app
```
## Deploy a new release

``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deployes those tags to the server
```

Releaese and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image

### Installing Analytics

Hyrax supports your choice of either Google Analytics or Matomo.  To enable analytics tracking and reporting features, follow the directions below.

Enable Analytics Features

In your .env file, set HYRAX_ANALYTICS to true, set either 'google' or 'matomo' for  HYRAX_ANALYTICS_PROVIDER, and set the date you would like reporting to start (ANALYTICS_START_DATE).  

```
HYRAX_ANALYTICS=true
HYRAX_ANALYTICS_PROVIDER=google
ANALYTICS_START_DATE=2021-08-21
```

If using google, you'll also need the following ENV variables:

```
GOOGLE_ANALYTICS_ID=UA-111111-1  # Universal ID (Currently Hyrax Analytics only works with Univeral (UA) accounts)
GOOGLE_OAUTH_APP_NAME=  
GOOGLE_OAUTHAPP_VERSION=
GOOGLE_OAUTH_PRIVATE_KEY_PATH= # store the .p12 file in the root of your application
GOOGLE_OAUTH_PRIVATE_KEY_SECRET=
GOOGLE_OAUTH_CLIENT_EMAIL=
```

Add these ENV variables if using Matomo:

```
MATOMO_SITE_ID=
MATOMO_BASE_URL=
MATOMO_AUTH_TOKEN=
``` 

Analytics Features

Once analytics is enabled, Hyrax will automatically install the JS tracking code.  Page views and downloads of a file set are recorded and sent to the selected analytics provider.  Admin users will have access to an expanded dashboard with details about how many vistors viewed a page, and how many visitors downloaded a file.  Easily find the top works by views, and most popular file downloads!
