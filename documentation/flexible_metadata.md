# Flexible TODOs
- add the schema loader
- add the flexible schema model
- make koppie flexible with includes
- document steps to make existing app flexible
- generator options to add flexibility


## Configuration

Setting the Hyrax configuration option `flexible` to true will disable `file_set_include_metadata`, `work_include_metadata`, `work_default_metadata`, `collection_include_metadata`, and `admin_set_include_metadata`. These flags allow the M3 profile to control all fields within the curation concerns. This also means that admins are responsible for making sure basic default metadata is present in that profile.