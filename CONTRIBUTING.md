# Contributing Guide

We want your help to make [Hyrax's documentation](http://hyrax.projecthydra.org/) great. There are a few guidelines that we need contributors to follow to make it easier to work together.

## Hydra Project Intellectual Property Licensing and Ownership

While code contributions require contributor license agreements to be on file with the Hydra Project Steering Group, contributing to Hyrax's documentation requires only that you agree to the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/) that covers all content available at hyrax.projecthydra.org.

## How to Contribute

There are two ways to contribute changes to the documentation.

1. *Easy*: send email to the [hydra-tech mailing list](https://groups.google.com/forum/#!forum/hydra-tech) and ask the community to make the change on your behalf.
2. *Advanced*: create a GitHub pull request.

If you choose option 2, here's a guide to help you.

### Via Pull Request

* Reporting Desired Changes
* Getting Set Up
* Documenting Code
* Committing Changes
* Submitting Changes

#### Reporting Desired Changes

* Make sure you have a [GitHub account](https://github.com/signup/free)
* Submit a [GitHub issue](./issues/new) by:
  * Clearly describing the change you'd like to see made

#### Getting Set Up

* [Fork the repository](https://github.com/projecthydra-labs/hyrax/fork) on GitHub
* Checkout the `gh-pages` branch
* Create a branch off of the `gh-pages` branch
  * E.g.: `git checkout -b fix_question_17`
  * Please avoid committing directly to the `gh-pages` branch.

#### Committing changes

* Make edits to the files you care to change.
* Add and commit your changes.
  * Your commit message should include a high level description of your work, e.g., "Expand answer to question #17 in the FAQ to more clearly describe the widget-y frobulator thingamajig."
* If you created an issue, you can close it by also including "Fixes #issue" (where "issue" is the issue number from GitHub) in your commit message. See [Github's blog post for more details](https://github.com/blog/1386-closing-issues-via-commit-messages)

#### Submitting Changes

* Read the article ["Using Pull Requests"](https://help.github.com/articles/using-pull-requests) on GitHub.
* Push your changes to a topic branch in your fork of the repository, e.g., `git push origin fix_question_17`
* Submit a pull request from your fork to the project via GitHub.

## Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
* [Pro Git](http://git-scm.com/book) is both a free and excellent book about Git.
* [A Git Config for Contributing](http://ndlib.github.io/practices/my-typical-per-project-git-config/)
