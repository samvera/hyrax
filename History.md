# History of Sufia releases

## 4.2.0

* Caches google analytics data in the database so we do not have to retrieve them each time the page is loaded [Carolyn Cole]
* Allows adopters to inject content into the layout's head block, needed by ScholarSphere to add a favicon [Mike Giarlo]
* Removes redundant title attributes for featured and recent works, fixes orphaned labels [Michael Tribone]
* Pins mini_magick for rubies < 2.1 [Carolyn Cole]
* Changes the way we log depositor change events [Mike Giarlo]
* Breaks cached stats migrations into dedicated generator [Mike Giarlo]
* Fixes bug with proxy setup in the install generator [Mike Giarlo]
* Fixes bug in batch editing javascript [Carolyn Cole]

## 4.1.0

* Adds proxy deposit, "sticky" proxies, and transfers of ownership (from ScholarSphere) [Mike Giarlo]
* Fixes bug with form fields attached to single-valued terms [Carolyn Cole]
* Converts specs to use RSpec 3 style [Mike Giarlo]

## 4.0.1

This release contains bug fixes and css fixes found after the Sufia 4.0 release. Upgrade to Sufia 4.0 first or follow the upgrade notes for 4.0 before upgrading to 4.0.1

* Moves featured reseacher above tag cloud [mtribone]
* Adds configurable translation to HTML element for error pages [mtribone]
* Removing second call to after_ajax [Carolyn Cole]
* Changing the timeout to reference this instead of self as self is undefined and this has the id
* Make sure a few required assets are explicitly listed on the asset pipeline. This removes the runtime error.
* Creates a default resque-pool.yml so that resque can process jobs without any manual configuration [Hector Correa]
* Fixing batch processing so the clock will go away when batches finish processing [Carolyn Cole]
* Adding the created date as the start date for the google analytics query.
* Allowing the default activity time to be configurable, and to set the default to 24 hours instead of a few hours like it currently is [Carolyn Cole]
* Refactoring Audit so it uses the file already loaded in memory instead of reloading the file many times to get at the audit log records in active record [Carolyn Cole]
* Adding screen reader tags to allow the screen reader access to delete the messages [Carolyn Cole]
* Switched plain text +/- buttons with glyphicons plus/remove. Removed word 'add' from some of the buttons so that they all look the same [Hector Correa]
* Changing from file path to label since the the base file name from box is a hash code and the label has the file name [Carolyn Cole]
* Adding I18N for facet labels so we do not get "Filter my Shareds" [Carolyn Cole]
* Moving tag cloud out of sufia.js so it can be more easily overriden [Carolyn Cole]
* Adding i18n translations to the form [Carolyn Cole]
* Moves layout and styles from ScholarSphere for new user dashboard to Sufia, moves styles into sufia folder, refactors variable names for CSS [mtribone]
* Fix test for the ntriples mime-type This was changed in ActiveFedora 7.1.1 [Justin Coyne]
* Allow Actor#update_visibility to be overriden (e.g. for embargo) [Justin Coyne]
* Typo in README [Joe Atzberger]
* Use correct XACML policy file [Adam Wead]
* Using Solr 4.9 under hydra-jetty 7.1 [Adam Wead]
* Forces to require v4.x [Hector Correa]
* Moving the location of the ZeroClipboard swf load from assets to the asset_path helper so it will work correctly in production [Carolyn Cole]

## 4.0.0

  * Make batch-edit more accessible [Adam Wead]
  * Changing so stats on public files can be viewed without logging in [Carolyn Cole]
  * hide pagination for screen readers [Brian Maddy]
  * Changing headers on home page to be configurable [Carolyn Cole]
  * improved accessibility for permissions editing and help popovers [Brian Maddy]
  * Sufia::BootstrapBreadcrumbsBuilder for rendering breadcrumbs [Adam Wead]
  * Adding aria roles and screen reader labels to make the upload more understandable for the screen reader [Carolyn Cole]
  * Adds labels and ARIA hints for screen-readers [Hector Correa]
  * Changing to not use the path if the label has already been set. The path can be more than 255 characters which messes with Fedora [Carolyn Cole]
  * Using breadcrumbs_on_rails [Adam Wead]
  * Updating my listing views to make it more usable for a screen reader [Carolyn Cole]
  * Adding check for collection so they display nicely in the gallery, instead of looking like a default document [Carolyn Cole]
  * removing icons in screen reader since they disable finding links by text if they are included and do not add to the sr user expericence [Carolyn Cole]
  * made search result metadata not use headers [Brian Maddy]
  * made tests work with newer version of devise [Brian Maddy]
  * put label before main search field [Brian Maddy]
  * improved accessibility of tag cloud [Brian Maddy]
  * Changes to LICENSE and README to reflect Hydra convention. Fixes #636 [Michael J. Giarlo]
  * Adding labels and moving title to link so screen reader will pick read better information. [Carolyn Cole]
  * Makes sure only visible files are picked up on the Recent Uploads panel [Hector Correa]
  * fixed deprecation warnings in spec/controller/* [Brian Maddy]
  * Removing Unknown attribute error when a trophy is show on the profile page [Carolyn Cole]
  * Characterization should only be loosly coupled to FullTextIndexing [Michael J. Giarlo]
  * Full module name for Legato::Model [Adam Wead]
  * removed a duplicate test, cleaned up some others [Brian Maddy]

## 4.0.0.rc2

  * made collections not crash in gallery view [Brian Maddy]
  * Changing from font-awesome-sass-rails to font-awesome-rails gem to allign with browse everything [Carolyn Cole]
  * Changing toggle to work correctly for glyphicon right and down [Carolyn Cole]
  * Using Sufia::Messages for batch update notifications [Adam Wead]
  * Batch edit now uses Bootstrap grid rather than HTML table. This fixes the scrollbar issue when editing field details. The links for details have also been fixed so that t
  * Adding a check to make sure the check all box exists before checking to see if it has been checked. [Carolyn Cole]
  * Chaged to use the follower i18n instead of the following [Carolyn Cole]
  * Updating to use the new bootstrap modal classes, and adding internationalization for the following follower [Carolyn Cole]
  * Show tab using anchor [Adam Wead]
  * Visibility status in show and list views [Adam Wead]
  * remove featured files that are deleted [Brian Maddy]
  * Fixes alignment issue with Terms of Service checkbox [Hector Correa]
  * Removed unused autoloads [Justin Coyne]
  * made long facet labels and images not cause div explosions [Brian Maddy]
  * Removes a document from the featured work list when the document is not public anymore [Hector Correa]
  * Move processing message to locale file and add punctuation. [Michael J. Giarlo]
  * fixed sorting issue on 'recently uploaded' [Brian Maddy]
  * Refactor GenericFile#related_files [Justin Coyne]
  * Redirect to MyController [Adam Wead]
  * Remove another deprecation [Justin Coyne]
  * Remove more deprecation warnings [Justin Coyne]
  * Use engine_cart for building the test app [Justin Coyne]
  * removed 40 deprecation warnings [Brian Maddy]
  * swapped order of items in dashboard sidebar [Brian Maddy]
  * made collection show not have a redundant title and description [Brian Maddy]
  * Refactoring the css on the tag cloud to be centered, show a space between terms (or phrases) and show color [Carolyn Cole]
  * Changing logger to ActiveFedora::Base.logger or Rails.logger [Carolyn Cole]
  * Combining event streams for dashboard and getting rid of unused column [Carolyn Cole]
  * Fixes alignment issue with Save Descriptions button [Hector Correa]
  * Collection show now displays list of files using the normal file collection layout [Hector Correa]
  * Fixed alignment of Edit Selected button [Hector Correa]
  * Removed deprecations for assigning scalars to multivalued fields [Justin Coyne]
  * Changing collections folder to new icon and resizing the icon so it is not so big [Carolyn Cole]
  * Move ModelMethods to concerns directory [Justin Coyne]
  * Move jobs into app/jobs [Justin Coyne]
  * Patching after gem updates [Adam Wead]
  * Rake task info should write to stdout [Adam Wead]
  * Adds Collections area to generic_file view, showing collections this file belongs to (if any). [kerchner]
  * Override assign_pid rather than monkeypatch ActiveFedora [Justin Coyne]
  * License Descriptions button is gone from the Upload page and instead the descriptions are displayed when clicking on the question mark icon. Descriptions are still displa
  * Display collections button only for my files [Adam Wead]
  * Fixing collection display issues, refs #9319 [mtribone]
  * Add Google Scholar-style meta tags to GF show view [Michael J. Giarlo]
  * Replaced orphan "What's This" button with two individual tooltips for Visibility and Share With on the Upload file page. [Hector Correa]
  * Fix alignment issue between section title and search box. [Hector Correa]
  * Fixed issue in which the tooltip for the upload button was being DETECTED on the wrong spot (i.e. outside of the button) in Chrome. [Hector Correa]
  * Using Blacklight constraints in my files display [Adam Wead]
  * Use plus icon for create collection option. Hide 'My Dashboard' title for XS devices. [Hector Correa]
  * Replace deprecated method has_next? with last_page? [Justin Coyne]
  * Adjusted the columns to stack without overlapping at smaller resolutions [Hector Correa]
  * Added partial to user utility button to allow each app to add their custom options [Hector Correa]
  * Added 'View Collections' button to the dashboard [Hector Correa]
  * Updating Add More Descriptions java script to work with the latest jquery show hide, and additionally aligning the fields left instead of middle to match up with batch me
  * Merge pull request #567 from projecthydra/file-table [Justin Coyne]
  * My table layout and collection info [Adam Wead]
  * Adding partials for index so it is easier to override individual parts, and update the many icons for upload to be the same [Carolyn Cole]
  * Unify MIME type-checking methods for Solr documents and GenericFiles [Michael J. Giarlo]
  * Adding blacklight galery update to the css [Carolyn Cole]
  * Show number of files and size of collection [Adam Wead]
  * User utility button now takes user to the dashboard when clicking on the user name. Replaced edit profile button with view profile button. Added view tests for new functi
  * Adding vnd.oasis.opendocument.text which fits is giving back for some docx [Carolyn Cole]
  * Add full-text indexing to sufia [Michael J. Giarlo]
  * bootstrap-sass 3.2 breaks our dropdownss [Adam Wead]
  * padding for sort,reduce table borders, position changes for cog. fixes #9283 [mtribone]
  * better responsive header and search form [Adam Wead]
  * Rendering itemprop for custom show fields [Adam Wead]
  * Removing username in mobile view [Adam Wead]
  * Test schema.org microdata embedding [Michael J. Giarlo]
  * Clarify where to add sufia line to application.js [Coding ZEAL]
  * Redirect to dashboard upon login [Adam Wead]
  * Update list of included features in README [Michael J. Giarlo]
  * Add Twitter card/Opengraph meta tags for rich social media linking to generic file show view [Michael J. Giarlo]
  * Makes generic_files edit and show views rely on shared records/edit_fields and records/show_fields. [Matt Zumwalt]
  * Taking advantage of browse everything filename since box does not include the file name in the url. [Carolyn Cole]
  * Adds full metadata editing for Collections (same DC fields as GenericFiles) Fixes hydra-editor style partials in views/records. refs gwu-libraries/gw-sufia#82 refs gwu-l
  * Moves Sufia Collection behaviors into a module [Matt Zumwalt]
  * Configure dashboard notification limits [Adam Wead]
  * Adding header metadata so the page reduces to a small size on the phone. [Carolyn Cole]
  * I18N text for my items [Adam Wead]
  * Added /collections/ case to make breadcrumbs behavior consistent. Required addition of collections_list to localization. Added _breadcrumbs.html.erb test. Fixes gwu-libra
  * Create collection and upload buttons [Adam Wead]
  * Bootstrap3 button classes, fixes #510 [Adam Wead]
  * More Boostrap 2 -> 3 upgrades. Fixes #528, #508 [Justin Coyne]
  * Changing magic to time so the icon show up when the files are being processed and include the icon under the check box instead of in a separate column. [Carolyn Cole]
  * Alerts when editing permissions, fixes #498 [Adam Wead]
  * Don't convert avatar images, fixes #527 [Adam Wead]
  * Remove SufiaHelper#link_back_to_catalog, fixes #323 [Adam Wead]
  * Stats for files and collections, fixes #454 [Adam Wead]
  * Capture original file size [Adam Wead]
  * Moving bootstrap tabs to asset pipeline to extract local javascript from pages. resolves #514 [Carolyn Cole]
  * SSL compatibile usage of google fonts [Matt Zumwalt]
  * tag cloud links point to catalog instead of root path [Matt Zumwalt]
  * specifying button type [Adam Wead]
  * changing to bootstrap 3 danger from important to get the red background for permissions, and fixing collection detail spacing when there is no description [Carolyn Cole]
  * Upgrade to rspec 3. Fixes #493 [Carolyn Cole]
  * Removed extraneous colons preceding key names. Fixes #516 [kerchner]
## 4.0.0.rc1

  * Use the bootstrap_form helpers (bootstrap_forms is no longer available) [Justin Coyne]
  * Lock hydra-editor to ~> 0.3.0 [Justin Coyne]
  * Use mailboxer 0.12.0 [Justin Coyne]
  * Allow hydra-head 7.1.0 to be used [Justin Coyne]
  * Drop no longer used submodule for hydra-jetty [Michael J. Giarlo]
  * Rename releasing document because reasons. [Michael J. Giarlo]
  * Updating release process documentation. [Michael J. Giarlo]
  * Moved to release notes [Michael J. Giarlo]
  * Changing all icons to glyph icons except the social ones because bootstrap does not include those [Carolyn Cole]
  * Adding missing methods to My controllers [Adam Wead]
  * Added additonal span and classes to fix thumbnail image hogging column and refactored HTML/CSS. fixes #SCM-9283 [Carolyn Cole]
  * Updating modals and fixing facet features #428 [Adam Wead]
  * Screen reader should say 'items' #485 [Adam Wead]
  * making new office document thumbnails visible. [Carolyn Cole]
  * Removing unused blacklight overrides.  Only keeping the ones we need to change blacklight default behavior. Pinning respec to 2.99 [Carolyn Cole]
  * Label featured works appropriately and allow overriding this label [Michael J. Giarlo]
  * Creates generators to upgrade 3.7.2 instances to 4.0.0 [Michael J. Giarlo]
  * Refactor views to support collection links [Justin Coyne]
  * Removing instances of :local_js and :js_head [Adam Wead]
  * Noid.namespaceize should not append a second namespace onto a pid. Previously if the passed in identifier had a namespace that was not the same as the configure namespace it would append a second namespace to the identifier. This would create an invalid pid. [Justin Coyne]
  * Adding collections to the filter for searching. resolves #429 [Carolyn Cole]
  * Correcting Rails app integration issues [Adam Wead]
  * removing unused layout method [Carolyn Cole]
  * Adding bootstrap 3 modal classes to generic_file modals [Carolyn Cole]
  * Changing the layout for the catalog controller to always include two columns, since the homepage is now a separate controller [Carolyn Cole]
  * Add image/tiff as a recognized image type [Justin Coyne]
  * Preparing for 4.0.0.beta4 release [Justin Coyne]
  * Bump version to 4.0.0.beta4 [Justin Coyne]
  * New dashboard functionality with unified search [Adam Wead]
  * Uploaded and modified dates should not be included in the display of descriptive metadata [Michael J. Giarlo]
  * Moving repeatative html up the stack and removing hard coded labels [Carolyn Cole]
  * Inject Sufia::SolrDocumentBehavior with the sufia generator instead of the sufia-models generator. This keeps the module and geneator together in the same gem. [Justin Coyne]
  * Removing sufia route set from catalog path as it does not exist there.  This causes an error in production only. [Carolyn Cole]
  * Fixes progress bar for jquery-file-upload [Michael J. Giarlo]
  * Glyphicons come with bootstrap-sass, remove this old version [Justin Coyne]
  * Upgrade to mailboxer 0.12.0.rc2 (from rc1) [Justin Coyne]
  * Updating README as per committer's call on May 19th [Adam Wead]
  * Index title with `_sim` suffix in addition to the existing `_tesim` suffix This enables an exact match search on title: ```ruby GenericFile.where(desc_metadata__title_tesim: 'anoabo00-00001.jp2').map {|f| f.title.first } \# => ["anoabo00-00001.jp2", "anoabo00-00002.jp2", "anoabo00-00003.jp2"] GenericFile.where(desc_metadata__title_sim: 'anoabo00-00001.jp2').map {|f| f.title.first } \# => ["anoabo00-00001.jp2"] ``` [Justin Coyne]
  * Fixed unified search layout and hover states. [mtribone]
  * Separate model noid concerns from controller noid concerns [Justin Coyne]
  * bump version to beta 3 [Justin Coyne]
  * Restore schema.org microdata to GenericFile show view; Add schema.org microdata to Collection show view; Take advantage of Blacklight's schema.org microdata hooks. [Michael J. Giarlo]
  * Set up all the events in the initializer [Justin Coyne]
  * Version bump to 4.0.0.beta3 [Justin Coyne]
  * Cease auto characterizing on save and use a real Actor. This makes testing far easier. Fixes #232 [Justin Coyne]
  * Changing the forwarding location to be where the files now are instead of where they once were. resolves #434 [Carolyn Cole]
  * Changing to only public works can be featured. resolves #395 [Carolyn Cole]
  * Fixing sytax error introduced by Ruby/Rails style reformat [Carolyn Cole]
  * Refactor the file controller update method for clarity [Justin Coyne]
  * Use modern Ruby/Rails style guidelines [Michael J. Giarlo]
  * Generate thumbnails for office documents [Michael J. Giarlo]
  * Move GenericFile concerns to standard autoload paths [Justin Coyne]
  * Move the event job launching out of Actions. events aren't in sufia-models [Justin Coyne]
  * Removed duplicate object allocations [Justin Coyne]
  * Eliminate double save and stop using exceptions for flow control [Justin Coyne]
  * Encapsulate browse_everything upload in a module [Justin Coyne]
  * Put revert and update actions in the Actions module [Justin Coyne]
  * Allow users to add files to collections. Use the Boostrap modal rather than a custom modal. [Justin Coyne]
  * Only put the javascript for tinymce on the page one time. This allows the javascript test to pass. [Justin Coyne]
  * added dashboard tabs and moved file list to those tabs [Brian Maddy]
  * Setting text area id and adding jquery loop to allow for multiple content blocks to be on the same page.  resolves #415 [Carolyn Cole]
  * Query Google Analytics for file usage information and display with Flot JQuery [Adam Wead]
  * Moved controller concerns from lib/ to app/controllers/concerns/. [dchandekstark]
  * Added grid view for search results and collections view [Justin Coyne]
  * There is no longer two recent blocks on the home page, so clean up the home page controller to only have the one that shows all files. [Carolyn Cole]
  * Refactor the controllers to cleanup after the homepage_controller was added [Justin Coyne]
  * Adding an editable block for marketing content on the homepage header [Carolyn Cole]
  * Add collections [Justin Coyne]
  * Unify the home page search Fixes http://scm.dlt.psu.edu/issues/9142 [Justin Coyne]
  * Add source and bibliographicCitation DC terms to the metadata datastream [Justin Coyne]
  * moving homepage to it's own controller [Carolyn Cole]
  * added videojs fonts to precompile and made rake clean stop spring [Brian Maddy]
  * Version should be updated in all three locations. [Michael J. Giarlo]
  * add default value so config.usage_statistics is defined [Jim Coble]
  * Test for an XHR request, not for a javascript format [Justin Coyne]
  * Check to make sure BrowseEverthing is defined If you're only using sufia-models, then BrowseEverthing is not defined and you get an error. [Justin Coyne]
  * Ship the video-js fonts [Justin Coyne]
  * Allow endnote to be injected into a rails 4.0 or 4.1 file [Justin Coyne]
  * VirusFoundError should live in sufia-models [Justin Coyne]
  * Allow rails 4.1 to be used [Justin Coyne]
  * Modify how the pages controller and helper work so that you do not have to be logged in before viewing the page. [Carolyn Cole]
  * Changing to 2.1.1 to avoid the issue with 2.1.0 [cam156]
  * Update SUFIA_VERSION [cam156]
  * Update SUFIA_VERSION [cam156]
  * upping the version so people know the current UI changes are breaking [Carolyn Cole]
  * Refactor styles.css and create additional style sheets for features and sections. refs #SCM-9141 [Michael Tribone]
  * Template, home page, dashboard, edits to upgrade to Bootstrap3 and update look [Carolyn Cole]
  * Fixing dashboard facets to be bootstrap 3 compliant and updating pending dashboard test to be a passing test. [Carolyn Cole]
  * Upgrade mailboxer to 0.12.0.rc1 [Justin Coyne]
  * Drag and drop to order featured works [Justin Coyne]
  * [tagcloud] improving sort feature & made tagcloud properly configurable [Matt Zumwalt]
  * Add usage statistics to the user interface [Michael J. Giarlo]
  * using gsub to remove require tree, which removes javascript error in Chrome [Carolyn Cole]
  * Fix tests that broke as a result of a merge [Justin Coyne]
  * checking the frame rate as a number so 30 is equal to 30.0 [Carolyn Cole]
  * Re-add the generic_files stylesheet which was removed in #359 [Justin Coyne]
  * Use the User.to_param to craft paths. Fixes #367 [Justin Coyne]
  * Refactor user factories [Justin Coyne]
  * Add all show fields to default all_fields search in generator, so that there's a better search experience out of the box. [dchandekstark]
  * Initialize the javascript on page:load events for Turbolinks support [Justin Coyne]
  * Factor out PropertiesDatastream behavior to a concern to facilitate overriding [dchandekstark]
  * Add featured works to the homepage [Justin Coyne]
  * Refactor Trophies javascript. All trophy scripts should use the TrophyHelper#display_trophy_link Add the `trophy-class` back to the user's profile page. The script now updates the link text depending on the current state of the trophy. Trophies should work with Turbolinks now. [Justin Coyne]
  * Restrict rails to ~> 4.0.  4.1.0 causes errors with mailboxer [Justin Coyne]
  * [tagcloud] adding sort feature to tag cloud [Matt Zumwalt]
  * switched to ajax and jquery-based tag cloud [Matt Zumwalt]
  * Don't show the tinymce editor until the edit button is pushed [Justin Coyne]
  * Edit the about page with the TinyMCE editor [Justin Coyne]
  * only render tag cloud section on homepage if a blacklight query has been run. (ie don't render on login page) [Matt Zumwalt]
  * Added tinymce editor for featured researcher [Justin Coyne]
  * only render tag cloud section on homepage if a blacklight query has been run. (ie don't render on login page) [Matt Zumwalt]
  * Adding stylesheet and fixing login page error on layout [Carolyn Cole]
  * browse-everything tab uses localization for tab/button labels [Matt Zumwalt]
  * adding tag cloud helper and displaying it in homepage [Matt Zumwalt]
  * Bootstrap 3 ui changes [Carolyn Cole]
  * removing dropbox-specific support (replaced by browse-everything) [Matt Zumwalt]
  * added browse-everything for uploads [Matt Zumwalt]
  * Update to hydra-head 7.0.1 [Justin Coyne]
  * Upgrading sufia to the Blacklight 5 and Hydra-Head 7 [Carolyn Cole]
  * Adding a description to the all:release task so it will show up with rake -T [Carolyn Cole]
  * Update video.js to 4.5.1 [Justin Coyne]
  * Move font-awesome-sass-rails to be an internal dependency and not required in the Gemfile [Justin Coyne]
  * Clean up spacing [Justin Coyne]

## 3.7.0

  * The UsersController needs to set @trophies to a list of GenericFiles [Justin Coyne]
  * Removed patches for rails 3	 [Justin Coyne]
  * Short-circuit freshclam for a faster build	 [Michael J. Giarlo]
  * Use blacklight 4.5 methods for accessing the search_session. Fixes #296	  [Justin Coyne]
  * Test with ruby 2.1.0 final release	  [Justin Coyne]
  * Simplify tests for GenericFile#related_files	  [Justin Coyne]
  * Remove duplicate includes. Fixes #289	  [Justin Coyne]
  * Remove non-functioning rake tasks …	  [Justin Coyne]
  * Better documentation for GenericFile#related_files [ci skip]	[Justin Coyne]
  * Linked in handle seems to have been missed in the permitted attibiute… …	[Carolyn Cole]
  * Updated: - Don't need to exlicity add 'jettywrapper' to Gemfile b/c added by hydra:head generator (called by sufia generator)
             - Don't need to remove public/index.html (Rails 4 presumably)
             - Run `rake jetty:clean` instead of hydra:jetty generator -- does the same thing
             - Added note that fits can be installed with homebrew (and may require adding a symlink)
             	 [David Chandek-Stark]
  * Upgrade blacklight to 4.6	  [Justin Coyne]
  * Allowing the link to either be sufia based or blacklight based [Carolyn Cole]
  * Removing extra_head_content, and paginate deprication warnings [Carolyn Cole]
  * Remove deprecated method paginate_rsolr_response. Fixes #312 [Justin Coyne]
  * Moving single use link java script into asset pipeline. [Carolyn Cole]
  * Update to blacklight 4.7	 [Justin Coyne]
  * Modifying how zclip works when a flash player is not present, since t… …	 [Carolyn Cole]
  * Upgrading video.js to the latest version so it will work in firefox, … …	 [Carolyn Cole]
  * Removing hard coded asset paths, which do not work in production. Whi… …	 [Carolyn Cole]
  * Fixing audiojs to only display if audio is not supported by the brows… …	 [Carolyn Cole]

## 3.6.0

## 3.4.0

  * Handle facets with 3 or more words [Jeremy Friesen]
  * Fixed show links in Users#index [Andrew Curley]
  * Update to AF 6.7.0 [Justin Coyne]
  * Adding more verbose logging to specs [Jeremy Friesen]
  * Update to Blacklight 4.5.0 [Justin Coyne]
  * Removing migration templates from Sufia (they are in sufia-models) [Justin Coyne]
  * Removed HTML align property from views [Justin Coyne]
  * Relax the Resque spec [Justin Coyne]
  * Pinned to hydra-head ~> 6.4.0 [Justin Coyne]
  * Moved trophies related methods to Trophies module [Justin Coyne]
  * Move mime type related methods into MimeTypes module [Justin Coyne]
  * Extract version methods into its own module [Justin Coyne]
  * Extract metadata into its own module [Justin Coyne]
  * AccessRight has moved into HydraHead [Justin Coyne]
  * Remove Visibility, which was moved into hydra-head [Justin Coyne]
  * Fix deprecation warnings by switching to Hydra::AccessControls::Permissions [Justin Coyne]

## 3.3.0

  * Fix authorities deprecations [Justin Coyne]
  * Fix deprecation on MailboxController [Justin Coyne]
  * blacklight 4.4.1/0 doesn't work with kaminari > 0.14.1 See projectblacklight/blacklight#614 [Justin Coyne]
  * Allow acts_as_follower to be 0.2.0 for Rails 4 support [Justin Coyne]
  * Don't run blacklight and hydra generator twice [Justin Coyne]
  * Remove deprecation warning on Rails 4 [Justin Coyne]
  * Updating CONTRIBUTING.md as per Hydra v6.0.0 [Jeremy Friesen]
  * use cancan to authorize and validate single-use tokens. [Chris Beer]
  * Add ImageMagick as a software requirement in the README. [Jessie Keck]
  * split SingleUseLinkController into the authenticated controller that creates links, and a viewer that handles retrieving content for token-bearing users [Chris Beer]
  * remove explicit GenericFile references, and replace them with Rails magic [Chris Beer]
  * Refactor single-use links for style and clarity [Chris Beer]
  * add more gems to the gemfile for running tests from the gem root [Chris Beer]
  * add redis-server to the .travis.yml list of  services [Chris Beer]
  * Fix typos in README.md [Jessie Keck]

## 3.2.1

  * Updating gemspec to not limit on sufia-models [Jeremy Friesen]

## 3.2.0 - YANKED

  * Including on sufia-models subdir in gemspec [Jeremy Friesen]
  * Restoring the exception catching for migrations [Jeremy Friesen]
  * Publicizing #visibility_changed? [Jeremy Friesen]
  * Indicating attr_accessible is deprecated [Jeremy Friesen]
  * Removing ActiveModel::Dirty [Jeremy Friesen]
  * Upgrading ActiveFedora to latest 6.5 version [Adam Wead]

## 3.1.3

  * Removed old PSU licence [Justin Coyne]
  * Moved access rights from curate [Justin Coyne]
  * Adding an operride path where to redirect for when a file gets destroyed. [Carolyn Cole]
  * Use the deprecation settings on the correct module [Justin Coyne]

## 3.1.2

  * Track changes on visibility [Justin Coyne]
  * Use an ideomatic setter for visibility [Justin Coyne]
  * Upgrade mailboxer [Justin Coyne]
  * Adding a partial for the header of the dashboard to make the wording easier to override. [Carolyn Cole]
  * Improving the better migration template [Jeremy Friesen]

## 3.1.1

  * Extracting sufia generator behavior [Jeremy Friesen]
  * Don't use Sufia::Engine in the generated initializer [Justin Coyne]
  * Removed unused code [Justin Coyne]
  * Changed from a tag to span. fixes #32 [Carolyn Cole]

## 3.1.0

  * Make fits instructions more verbose [Carolyn Cole]
  * Adding one location to define/ override where the upload redirects to after a sucessfull upload [Carolyn Cole]
  * Added license to the gemspec [Justin Coyne]
  * fixed typo in require statement [Matt Zumwalt]
  * requires active_resource more cleanly [Matt Zumwalt]
  * updating facet views so that the blacklight helper_method will get called [Carolyn Cole]
  * Adds a spec for the ImportUrlJob [Michael J. Giarlo]
  * Fixed expecations for travis tests for #169 [Justin Coyne]
  * ModelMethods#apply_depositor_metadata should accept a user or a string like the method it overrides in HydraHead.  See: https://github.com/projecthydra/hydra-head/blob/9a5b2728be2046125d09376a6d78ad06d26548c3/hydra-core/lib/hydra/model_methods.rb#L12 [Justin Coyne]
  * Remove expand_path jazz from remaining specs [Michael J. Giarlo]
  * Codifying a pid based job [Jeremy Friesen]
  * Removing characterization save unless new_object? [Jeremy Friesen]
  * Adding $LOAD_PATH variable to dev rake task [Jeremy Friesen]
  * Bump dependency on hydra-derivatives [Justin Coyne]
  * Use add_file() rather than add_file_datastream() to ensure object label is set [Michael J. Giarlo]
  * Audio and video transcoding with hydra-derivatives [Justin Coyne]
  * Use hydra-derivatives for generating thumbnails [Justin Coyne]
  * ingest_local_file should ingest the file, not the filename [Justin Coyne]
  * Including deposit agreement on local import page [Matt Zumwalt]
  * UI for local ingest only appears in local ingest tab on upload page [Matt Zumwalt]
  * Putting test coverage for virus check into the right place [Matt Zumwalt]
  * local file ingest runs virus check [Matt Zumwalt]
  * testing outputs without relying on consistent array ordering [Matt Zumwalt]
  * UI text changes for local ingest [Matt Zumwalt]
  * removing unused fixtures [Matt Zumwalt]
  * cleanup of tests and method names around local ingest [Matt Zumwalt]
  * Display local ingest tab in Upload page when local import enabled [Matt Zumwalt]
  * Local ingest renders graceful error message if User does not define a directory path [Matt Zumwalt]
  * fixing scope of describe blocks in this test [Matt Zumwalt]
  * LocalFileIngestBehavior for FilesController [Matt Zumwalt]
  * The generator should create config/initializers/resque_config.rb [Justin Coyne]
  * Reindex everything scopes to sufia's namespace [Jeremy Friesen]
  * Remove css that doesn't appear to be used [Justin Coyne]

## 3.0.0

  * Update README.md paths for Sufia assets application.css and application.js [Jim Coble]
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
  * Dashboard search results test more specific -- avoids pagination causing false negatives [Matt Zumwalt]
  * explicit handling of kaminari pagination bug, plus info in install docs [Matt Zumwalt]
  * Test to confirm that pagination works -- fails because dashboard/pages routes are not properly inherited. [Matt Zumwalt]
  * Handle the odd values in the hidden fields on the generic_files/_permission.html.erb form.  These were added here: https://github.com/psu-stewardship/scholarsphere/commit/2a58d0c920cc87cad9a815b451613e3d327747e3#L9R5 I have no idea why. [Justin Coyne]
  * Add a comment in the generator about the Sufia route being the very last line [Justin Coyne]
  * Generated controller uses the search_layout method for determining layout [Justin Coyne]
  * Force a two column layout for dashboard [Justin Coyne]
  * Use hydra-head 6.3.0 [Justin Coyne]
  * Bump active-fedora version to 6.4.0.rc4 [Justin Coyne]
  * allowing non-sufia controllers to inherit dashboard behaviors and helpers smoothly [Matt Zumwalt]
  * Set a permission value that actually exists (e.g. 'read') [Justin Coyne]
  * Added attr_accessible [Justin Coyne]
  * Fix the version in sufia-models.gemspec so you can bundle install [Justin Coyne]

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
