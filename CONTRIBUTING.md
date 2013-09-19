# How to Contribute

We want your help to make Project Hydra great.
There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

## Hydra Project Intellectual Property Licensing and Ownership

All code contributors must have an Individual Contributor License Agreement (iCLA) on file with the Hydra Project Steering Group.
If the contributor works for an institution, the institution must have a Corporate Contributor License Agreement (cCLA) on file.

https://wiki.duraspace.org/display/hydra/Hydra+Project+Intellectual+Property+Licensing+and+Ownership

You should also add yourself to the `CONTRIBUTORS.md` file in the root of the project.

## Contribution Tasks

* Reporting Issues
* Making Changes
* Submitting Changes
* Merging Changes

### Reporting Issues

* Make sure you have a [GitHub account](https://github.com/signup/free)
* Submit a [Github issue](./issues) by:
  * Clearly describing the issue
    * Provide a descriptive summary
    * Explain the expected behavior
    * Explain the actual behavior
    * Provide steps to reproduce the actual behavior

### Making Changes

* Fork the repository on GitHub
* Create a topic branch from where you want to base your work.
  * This is usually the master branch.
  * To quickly create a topic branch based on master; `git branch fix/master/my_contribution master`
  * Then checkout the new branch with `git checkout fix/master/my_contribution`.
  * Please avoid working directly on the `master` branch.
  * You may find the [hub suite of commands](https://github.com/defunkt/hub) helpful
* Make commits of logical units.
  * Your commit should include a high level description of your work in HISTORY.textile 
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are [well formed](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
* If you created an issue, you can close it by including "Closes #issue" in your commit message. See [Github's blog post for more details](https://github.com/blog/1386-closing-issues-via-commit-messages)

```
    Present tense short summary (50 characters or less)

    More detailed description, if necessary. It should be wrapped to 72
    characters. Try to be as descriptive as you can, even if you think that
    the commit content is obvious, it may not be obvious to others. You
    should add such description also if it's already present in bug tracker,
    it should not be necessary to visit a webpage to check the history.

    Include Closes #<issue-number> when relavent.

    Description can have multiple paragraphs and you can use code examples
    inside, just indent it with 4 spaces:

        class PostsController
          def index
            respond_with Post.limit(10)
          end
        end

    You can also add bullet points:

    - you can use dashes or asterisks

    - also, try to indent next line of a point for readability, if it's too
      long to fit in 72 characters
```

* Make sure you have added the necessary tests for your changes.
* Run _all_ the tests to assure nothing else was accidentally broken.
* When you are ready to submit a pull request

### Submitting Changes

[Detailed Walkthrough of One Pull Request per Commit](http://ndlib.github.io/practices/one-commit-per-pull-request/)

* Read the article ["Using Pull Requests"](https://help.github.com/articles/using-pull-requests) on GitHub.
* Make sure your branch is up to date with its parent branch (i.e. master)
  * `git checkout master`
  * `git pull --rebase`
  * `git checkout <your-branch>`
  * `git rebase master`
  * It is likely a good idea to run your tests again.
* Squash the commits for your branch into one commit
  * `git rebase --interactive HEAD~<number-of-commits>` ([See Github help](https://help.github.com/articles/interactive-rebase))
  * To determine the number of commits on your branch: `git log master..<your-branch> --oneline | wc -l`
  * Squashing your branch's changes into one commit is "good form" and helps the person merging your request to see everything that is going on.
* Push your changes to a topic branch in your fork of the repository.
* Submit a pull request from your fork to the project.

### Merging Changes

* It is considered "poor from" to merge your own request.
* Please take the time to review the changes and get a sense of what is being changed. Things to consider:
  * Does the commit message explain what is going on?
  * Does the code changes have tests? _Not all changes need new tests, some changes are refactorings_
  * Does the commit contain more than it should? Are two separate concerns being addressed in one commit?
  * Did the Travis tests complete successfully?
* If you are uncertain, bring other contributors into the conversation by creating a comment that includes their @username.
* If you like the pull request, but want others to chime in, create a +1 comment and tag a user.

# Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
* [Pro Git](http://git-scm.com/book) is both a free and excellent book about Git.
* [A Git Config for Contributing](http://ndlib.github.io/practices/my-typical-per-project-git-config/)
