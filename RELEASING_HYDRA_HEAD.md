### Follow these instructions to release a new version of hydra-head, including the contained gems: hydra-core and hydra-access-controls.

1. Bump version number in [HYDRA_VERSION](https://github.com/projecthydra/hydra-head/blob/master/HYDRA_VERSION).
1. Modify [the changelog](https://github.com/projecthydra/hydra-head/blob/master/HISTORY.textile) to include changes in the version (which can usually be pulled from commit messages).
1. Push your changes: `git push`
1. Create a [GitHub release](https://github.com/projecthydra/hydra-head/releases/new) and copy/paste the changes from the changelog in the prior step. If steps are required to upgrade to the new version, make sure to include these changes.
1. Release the gem to rubygems.org: `rake all:release`
  * If this is your first time pushing to rubygems.org, you will be prompted for your rubygems.org credentials, in which case do the following: `gem push; rake all:release`
1. Create [release notes in GitHub](https://github.com/projecthydra/hydra-head/releases/new). In the new release, include at least a block with upgrade notes and a block showing the changelog (copy from earlier step). (See [an example](https://github.com/projecthydra/hydra-head/releases/tag/v9.2.2).)
1. Send a release message to [hydra-tech](mailto:hydra-tech@googlegroups.com), [hydra-community](mailto:hydra-community@googlegroups.com), and [hydra-releases](mailto:hydra-releases@googlegroups.com) describing the changes (which you can copy from the GitHub release).
