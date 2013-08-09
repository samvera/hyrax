# History of Sufia releases

## 3.1.0
* Make fits instructions more verbose [Carolyn Cole]

* Adding one location to define/ override where the upload redirects to after a
sucessfull upload [Carolyn Cole]

* Added license to the gemspec [Justin Coyne]

* fixed typo in require statement [Matt Zumwalt]

* requires active_resource more cleanly [Matt Zumwalt]

* updating facet views so that the blacklight helper_method will get called
[Carolyn Cole]

* Adds a spec for the ImportUrlJob [Michael J. Giarlo]

* Fixed expecations for travis tests for #169 [Justin Coyne]

* ModelMethods#apply_depositor_metadata should accept a user or a string like the
method it overrides in HydraHead.  See:
https://github.com/projecthydra/hydra-head/blob/9a5b2728be2046125d09376a6d78ad06d26548c3/hydra-core/lib/hydra/model_methods.rb#L12
[Justin Coyne]

* Remove expand_path jazz from remaining specs [Michael J. Giarlo]

* Codifying a pid based job [Jeremy Friesen]

* Removing characterization save unless new_object? [Jeremy Friesen]

* Adding $LOAD_PATH variable to dev rake task [Jeremy Friesen]

* Bump dependency on hydra-derivatives [Justin Coyne]

* Use add_file() rather than add_file_datastream() to ensure object label is set
[Michael J. Giarlo]

* Audio and video transcoding with hydra-derivatives [Justin Coyne]

* Use hydra-derivatives for generating thumbnails [Justin Coyne]

* ingest_local_file should ingest the file, not the filename [Justin Coyne]

* Including deposit agreement on local import page [Matt Zumwalt]

* UI for local ingest only appears in local ingest tab on upload page [Matt
Zumwalt]

* Putting test coverage for virus check into the right place [Matt Zumwalt]

* local file ingest runs virus check [Matt Zumwalt]

* testing outputs without relying on consistent array ordering [Matt Zumwalt]

* UI text changes for local ingest [Matt Zumwalt]

* removing unused fixtures [Matt Zumwalt]

* cleanup of tests and method names around local ingest [Matt Zumwalt]

* Display local ingest tab in Upload page when local import enabled [Matt
Zumwalt]

* Local ingest renders graceful error message if User does not define a directory
path [Matt Zumwalt]

* fixing scope of describe blocks in this test [Matt Zumwalt]

* LocalFileIngestBehavior for FilesController [Matt Zumwalt]

* The generator should create config/initializers/resque_config.rb [Justin Coyne]

* Reindex everything scopes to sufia's namespace [Jeremy Friesen]

* Remove css that doesn't appear to be used [Justin Coyne]


## 3.0.0
* Update README.md paths for Sufia assets application.css and application.js [Jim
Coble]

* Moving resque rake task to sufia-models [Jeremy Friesen]

* Resque should use the redis instance configured in redis.yml [Justin Coyne]

* Profile link should generate a valid route. Fixes #150 [Justin Coyne]

* Updating CONTRIBUTING.md as per Hydra v6.0.0 [Jeremy Friesen]

* Delete all needs a delete HTTP method [Justin Coyne]

* Put the specific version of kaminari we need into the test app [Justin Coyne]

* Removed deprecated use of mock() and stub() [Justin Coyne]

* Simpler rspec run [Justin Coyne]

* Fix routing spec [Justin Coyne]

* Replaced cucumber with feature specs [Justin Coyne]

* Use resourceful routes for users [Justin Coyne]

* Removed duplicate tasks [Justin Coyne]

* Switch require spec_helper to relative [Justin Coyne]

* Support rspec-rails 2.14 [Justin Coyne]

* Removed empty tests [Justin Coyne]

* Correct path for fonts [Justin Coyne]

* Use assets_path [Justin Coyne]

* Fix path to fixtures.rake [Justin Coyne]

* Add active_resource as a dependency [Justin Coyne]

* Distinct on notify_number is unnecessary [Justin Coyne]

* check all view, should supply the controller [Justin Coyne]

* Removed unused spec [Justin Coyne]

* Fixed path to rakefile [Justin Coyne]

* Fix test to work in an order independent manner [Justin Coyne]

* Single Use links should be randomly generated [Justin Coyne]

* Update paperclip gem [Justin Coyne]

* Handle attributes in a way that works with rails 3 or 4 [Justin Coyne]

* Fixed view spec [Justin Coyne]

* Devise is not required by sufia-models [Justin Coyne]

* Inherit the version of devise from blacklight [Justin Coyne]

* Move to a released version of blacklight_advanced_search [Justin Coyne]

* Rails 4 support [Justin Coyne]

* updating the readme based on mye experience running through it. [Carolyn Cole]

* The query for my uploads, should be me, not exclude me [Justin Coyne]

* Multiform should rename the fields correctly [Justin Coyne]

* more explicit editable docs test [Matt Zumwalt]

* Dashboard search results test more specific -- avoids pagination causing false
negatives [Matt Zumwalt]

* explicit handling of kaminari pagination bug, plus info in install docs [Matt
Zumwalt]

* Test to confirm that pagination works -- fails because dashboard/pages routes
are not properly inherited. [Matt Zumwalt]

* Handle the odd values in the hidden fields on the
generic_files/_permission.html.erb form.  These were added here:
https://github.com/psu-stewardship/scholarsphere/commit/2a58d0c920cc87cad9a815b451613e3d327747e3#L9R5
I have no idea why. [Justin Coyne]

* Add a comment in the generator about the Sufia route being the very last line
[Justin Coyne]

* Generated controller uses the search_layout method for determining layout
[Justin Coyne]

* Force a two column layout for dashboard [Justin Coyne]

* Use hydra-head 6.3.0 [Justin Coyne]

* Bump active-fedora version to 6.4.0.rc4 [Justin Coyne]

* allowing non-sufia controllers to inherit dashboard behaviors and helpers
smoothly [Matt Zumwalt]

* Set a permission value that actually exists (e.g. 'read') [Justin Coyne]

* Added attr_accessible [Justin Coyne]

* Fix the version in sufia-models.gemspec so you can bundle install [Justin
Coyne]



## 2.0.1
* Fix version of sufia-models

## 2.0.0
* Dropbox support
* Multiple layouts
* UnzipJob can handle directories
* Support for sufia and hydra-editor in the same app
* Subdividing the upload partial
* Lots of code cleanup


## 1.3.0
* Depends on Hydra::Controller::DownloadBehavior
* Upgraded to hydra-batch-edit 1.1 which includes session-less batches in hydra-collections
* Moved most of the Dashboard behavior into Sufia::DashboardBehavior to enable overriding
* Added Model to_s instead of using display_title
* Added after delivery hook to contact form controller
* Removed the version page
* various bug fixes


## 1.2.0
* DownloadController uses load_instance_from_solr for speed improvement
* Raise a AccessDenied error if a download is not allowed rather than show an image.
* Autoload the datastreams directory
* Set default variables (fits_path, id_namespace) in the engine config.

## 1.1.0
* Allows a user to deposit on behalf of another user
* Tweaks dashboard UI to be less busy: actions now in dropdown button
* Allows HTML tags in metadata helps to render
* Fixes notifications icon
* Raises routing errors in dev and test so they can be resolved
* Refactors users controller for easy re-use
* Adds JSON support to users controller
* Removes dependency on sitemap gem

## 1.0.0
* Initial API-stable release


