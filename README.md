# Hyrax: A Digital Repository Framework

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
* [Help](#help)
* [Working with Hyrax](#working-with-hyrax)
  * [Developing the Hyrax Engine](#developing-the-hyrax-engine)
    * [Contributing](#contributing)
    * [Release process](#release-process)
  * [Developing your Hyrax\-based Application](#developing-your-hyrax-based-application)
  * [Deploying your Hyrax\-based Application to production](#deploying-your-hyrax-based-application-to-production)
* [Acknowledgments](#acknowledgments)
* [License](#license)

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

![Samvera Logo](https://wiki.duraspace.org/download/thumbnails/87459292/samvera-fall-font2-200w.png?version=1&modificationDate=1498550535816&api=v2)

## License

Hyrax is available under [the Apache 2.0 license](LICENSE.md).
