# Flexible TODOs
* add the schema loader
* add the flexible schema model
- make koppie flexible with includes
  - does collection resource get the right schema include?
  - resource form based near helper removed... do we need it?
- document steps to make existing app flexible
- generator options to add flexibility
  - app generator should have a flag to turn flexible metadata on or off
    - that flag should set the `flexible` configuration option to `true` or `false`
    - that flag should set the `flexible_classes` correctly
    - that flag should set the `admin_set_include_metadata`, `collection_include_metadata`, `file_set_include_metadata`, or `work_include_metadata` configuration options to `false` or `true`


## Configuration

Setting the Hyrax configuration option `flexible` will allow the M3 profile loader and other flexible metadata elements to appear in the UI. It does not make any of the models themselves use flexible metadata.

There are two ways to make models flexible:

- Setting the Hyrax configuration option `flexible_classes` will toggle flexible metadata on for those classes automatically in Hyrax.
- Manually adding `acts_as_flexible` to any model class that inherits from `Hyrax::Resource`

You may choose whether to include the basic metadata always or to make them part of the flexible metadata profile. If you wish to use the default provided M3 profile, you must set `admin_set_include_metadata`, `collection_include_metadata`, `file_set_include_metadata`, or `work_include_metadata` to `false` so that basic metadata can instead be read from the flexible metadata profile. You can also set all of these from the ENV by setting the `HYRAX_DISABLE_INCLUDE_METADATA` environment variable to `true`.


### Koppie Flexible
HYRAX_FLEXIBLE=true
HYRAX_FLEXIBLE_CLASSES=Hyrax::AdministrativeSet,CollectionResource,FileSet,GenericWork,Monograph
HYRAX_DISABLE_INCLUDE_METADATA=true
