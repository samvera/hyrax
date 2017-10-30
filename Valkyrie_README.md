# Changelog for Hyrax 💖 Valkyrie

* FileSets no longer validate content using ClamAV (Hydra::Works::VirusCheck)
* Forms are now ChangeSets
* Actors are now ChangeSetPersisters
* ActiveFedora is out, Valkyrie is in.
  * Models do not have associations
  * Models do not validate themselves (See ChangeSets)
  * Models do not index themselves.
  * FileSet#original_file is now ???
* In FactoryGirl factories:
  * use create_for_repository instead of create
* Nested attributes (e.g. FileSet#permissions_attributes=) are out
* Switch from create_date_dtsi to created_at_dtsi and system_modified_dtsi to timestamp
* Instead of `GenericWorksController.curation_concern_type = GenericWork` use
  `GenericWorksController.resource_class = GenericWork`

## TODO:

* Map to RDF (in progress?)
* Persist as PCDM
* WebAC
* Presenters -> Draper Decorators?
* remove_representative_relationship should go into a change set (when you delete a FileSet that is a representative)
* Versioning
* paranoid_edit_permissions moves to ChangeSet
* Noid integration
* Embargo and Lease - Where should these be persisted
