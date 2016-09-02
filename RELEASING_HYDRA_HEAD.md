### Follow these instructions to release a new version of hydra-head, including the contained gems: hydra-core and hydra-access-controls.

1. In your local repo, on master, bump version number in [HYDRA_VERSION](https://github.com/projecthydra/hydra-head/blob/master/HYDRA_VERSION).
1. Push your changes without having added or committed them (the Rake release task will do it): `git push`. 
1. Create a [GitHub release](https://github.com/projecthydra/hydra-head/releases/new) and include changes in the version (which can usually be pulled from commit messages). If steps are required to upgrade to the new version, make sure to include these changes. (See [an example](https://github.com/projecthydra/hydra-head/releases/tag/v9.2.2).)
1. Release the gem to rubygems.org: `rake all:release`
  * If this is your first time pushing to rubygems.org, you will be prompted for your rubygems.org credentials, in which case do the following: `gem push; rake all:release`
1. Send a release message to [hydra-tech](mailto:hydra-tech@googlegroups.com), [hydra-community](mailto:hydra-community@googlegroups.com), and [hydra-releases](mailto:hydra-releases@googlegroups.com) describing the changes (which you can copy from the GitHub release).
