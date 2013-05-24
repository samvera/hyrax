# History of Sufia releases

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


