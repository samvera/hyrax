# Note about Versions

Hyrax has far more tags than released versions. This section provides context and wayfinding on navigating that reality.

The history of Hyrax involves the merging of [Sufia](https://github.com/samvera-deprecated/sufia) and [Curation Concerns](https://github.com/samvera-deprecated/curation_concerns). Each of those projects had their own releases and tags. In preserving commit history of the work, we collectively brought along those past tags (for better or for worse).

This means that we have a mix of Hyrax releases and associated tags as well as tags for those other gems' releases. Which can be confusing.

When you include Hyrax in your Gemfile, and reference a version (eg. `gem "hyrax", "~> 2.7"`), you are getting that version from Rubygems.  When you reference a tag (eg. `gem "hyrax", github: "samvera/hyrax", ref: "v2.7.0"`) you are getting that information from Github. Both are reasonable and dependent on your situation. In the case of the former, you're likely wanting stable releases. In the case of the latter, you may be looking to use specific commits that include unreleased bug fixes.

The place to find the canonical Hyrax releases is at https://rubygems.org/gems/hyrax, there you can find a list of versions. Those versions map to tags in Hyrax (e.g. you can expect that the version in Rubygems and the tag in Hyrax have the same code). The release notes for those versions will be further described in [Hyrax's releases](https://github.com/samvera/hyrax/releases/). However, within the Hyrax releases, you'll also see other non-released Hyrax versions. These are likely the tags from the preceding gems (`sufia` and `curation_concern`).

_**NOTE**: In our [2020-07-29 Samvera Tech call](https://wiki.lyrasis.org/display/samvera/Samvera+Tech+Call+2020-07-29), some of the contributors discussed how to proceed with our current state. This section is our effort to provide wayfinding around the confusing tag proliferation in our repository._

[Go back to the top-level documentation.](/README.md)