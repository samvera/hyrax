# Search Builders

Building searches is core to any Blacklight app, and CurationConcerns is no exception.  
This directory contains our Search Builders, so named because the design followed a builder pattern, meaning
that when invoked to set values, methods return the object itself, so that invocations can be chained, like:

```ruby
builder = Blacklight::SearchBuilder.new(processor_chain, scope)
            .rows(20)
            .page(3)
            .with(q: 'Abraham Lincoln')
```

However, at this level, many if not most of the additional methods do not follow this pattern.  
Refer to the `Blacklight::SearchBuilder` class if you want to be certain.  That leads to the next topic...

## Ancestry

Most of the SearchBuilders have `::SearchBuilder` as a parent or ancestor.  `::SearchBuilder` does not exist in any repo: it is generated
by Blacklight and modified by CurationConcerns.  Others descend from `Blacklight::SearchBuilder`, or various other relatives.  

### ::SearchBuilder

The generated parent class `SearchBuilder` descends from `Blacklight::SearchBuilder`.
As modified by CurationConcerns' installer, it includes additional modules and overrides.  So if your SearchBuilder has `::SearchBuilder` as a parent class, you are getting:
- [Blacklight::SearchBuilder](https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb) grandparent class
- [Blacklight::Solr::SearchBuilderBehavior](https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb) associated methods
- [Hydra::AccessControlsEnforcement](https://github.com/projecthydra/hydra-head/blob/master/hydra-access-controls/lib/hydra/access_controls_enforcement.rb) module
  -  [Blacklight::AccessControls::Enforcement](https://github.com/projectblacklight/blacklight-access_controls/blob/master/lib/blacklight/access_controls/enforcement.rb) ancestor of `Hydra::AccessControlsEnforcement`
- [CurationConcerns::SearchFilters](https://github.com/projecthydra/curation_concerns/blob/master/app/search_builders/curation_concerns/search_filters.rb)  module that itself includes:
  - [BlacklightAdvancedSearch::AdvancedSearchBuilder](https://github.com/projectblacklight/blacklight_advanced_search/blob/master/lib/blacklight_advanced_search/advanced_search_builder.rb) more magic for compound Boolean queries
  - [CurationConcerns::FilterByType](https://github.com/projecthydra/curation_concerns/blob/master/app/search_builders/curation_concerns/filter_by_type.rb) Collection vs. Work filtering, specifically the `filter_models` method

This is not a comprehensive list, but it is sufficient to trace some of the complexity of interaction between various layers.

## Development: AKA Doing Something Useful

Note, the `default_processor_chain` defined by `Blacklight::Solr::SearchBuilderBehavior` provides a way to extend functionality, but also many possible points of override (namely method names).  When you need to do something novel and additional, adding to the chain is completely reasonable.  For example:

```ruby
module MySearchBuilder
  extend ActiveSupport::Concern

  included do
    self.default_processor_chain += [:special_filter]
  end

  def special_filter(solr_parameters)
    solr_parameters[:fq] << "{!field f=some_field_ssim}#{...}"
  end
end
```

But to the extent that you are overriding (or undoing) something already done, `CurationConcerns::FileSetSearchBuilder` is a better example:

```ruby
module CurationConcerns
  class FileSetSearchBuilder < ::SearchBuilder
    include CurationConcerns::SingleResult

    # This overrides the filter_models in FilterByType
    def filter_models(solr_parameters)
      solr_parameters[:fq] << ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::FileSet.to_class_uri)
    end
  end
end
```

There is no point having the other `filter_models` methods apply `:fq`s that we then try to undo or overwrite.  In general, directly overwriting the whole `default_processor_chain` or solr parameters like `:fq` is less flexible than appending constraints sufficient for your use case.  In particular, you might find that you have overwritten components that implement access controls, thereby making your SearchBuilder less useful and less secure.  When in doubt, examine the actual solr queries produced.
