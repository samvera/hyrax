# Changelog for Hyrax 💖 Valkyrie

* FileSets no longer validate content using ClamAV (Hydra::Works::VirusCheck)
* Forms are now ChangeSets
* Actors are now ChangeSetPersisters
* ActiveFedora is out, Valkyrie is in.
  * Models do not have associations
  * Models do not validate themselves (See ChangeSets)
  * Models do not index themselves.
  * FileSet#original_file is now ???
* In FactoryBot factories:
  * use create_for_repository instead of create
* Nested attributes (e.g. FileSet#permissions_attributes=) are out
* Switch from create_date_dtsi to created_at_dtsi and system_modified_dtsi to timestamp
* Instead of `GenericWorksController.curation_concern_type = GenericWork` use
  `GenericWorksController.resource_class = GenericWork`
* You must switch to postgres (if you want to use the database adapter)
* `rake valkyrie_engine:install:migrations; rake db:migrate`
* Improve Tika File Characterization to allow for either use of the default Tika or with a pass to an external service
* Implement a characterization service that uses MediaInfo
* Change the activefedora i18n key to valkyrie
* ImportExportJob has gone away. It was not used elsewhere in Hyrax
* Update config/initializers/riiif.rb
  * set `Riiif::Image.file_resolver = Hyrax::Riiif::ValkyrieFileResolver.new`
  * Remove the `Riiif::Image.file_resolver.id_to_uri = lambda do |id| ... end `


## TODO:

* Phase 2 (Dec 2017-Jan 2018)
  * finish up getting test suite green
  * Versioning
  * Noid integration
  * Embargo and Lease - Where should these be persisted
  * paranoid_edit_permissions moves to ChangeSet
  * remove_representative_relationship should go into a change set (when you delete a FileSet that is a representative)
  * Get UI to a functional state
* Phase 3 (spring 2018)
  * Persist as PCDM (as migration path from Hyrax 2 to Hyrax 3)
    * Read from PCDM (migration path)
    * Write to PCDM (no migration at all)
  * WebAC
  * Presenters: Use Draper decorators?
