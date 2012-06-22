# -*- encoding : utf-8 -*-
# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|

  config[:default_solr_params] = {
    :qt => "search",
    :rows => 10 
  }
 
  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "generic_file__title_t",
    :heading => "generic_file__title_t",
    :display_type => "has_model_s"
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "generic_file__title_t",
    :record_display_type => "id"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  #
  # Hydra uses active_fedora_model_s by default for displaying Format because that field is automatically 
  # populated by active-fedora from your RELS-EXT.  You can change this to anything you want to use though.
  # for example, the sample Hydra::ModsAsset Datastream Class adds object_type_facet = "Article" in its to_solr method.\
  # You could use that as the format field instead of active_fedora_model_s to have a more nicer value displayed.
  # 
  #
  config[:facet] = {
    :field_names => (facet_fields = [
      "generic_file__contributor_facet",
      "generic_file__publisher_facet",
      "generic_file__subject_facet",
      "generic_file__resource_type_facet",
      "generic_file__format_facet",
      "generic_file__based_near_facet",
      "generic_file__tag_facet"

    ]),
    :labels => {
      "generic_file__contributor_facet"     => "Contributor",
      "generic_file__publisher_facet"       => "Publisher",
      "generic_file__subject_facet"         => "Subject",
      "generic_file__resource_type_facet"   => "Resource Type",
      "generic_file__format_facet"          => "Format",
      "generic_file__based_near_facet"      => "Location",
      "generic_file__tag_facet"             => "Tag"
    },
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.     
    :limits => {
      "subject_topic_facet" => 20,
      "language_facet" => true
    }
  }

  # Have BL send all facet field names to Solr, which has been the default
  # previously. Simply remove these lines if you'd rather use Solr request
  # handler defaults, or have no facets.
  config[:default_solr_params] ||= {}
  config[:default_solr_params][:"facet.field"] = facet_fields

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  config[:index_fields] = {
    :field_names => [
      "generic_file__contributor_display", 
      "generic_file__creator_display", 
      "generic_file__title_display", 
      "generic_file__description_display", 
      "generic_file__publisher_display", 
      "generic_file__date_created_display", 
      "generic_file__date_uploaded_display", 
      "generic_file__date_modified_display", 
      "generic_file__subject_display", 
      "generic_file__language_display", 
      "generic_file__rights_display", 
      "generic_file__resource_type_display", 
      "generic_file__format_display", 
      "generic_file__identifier_display", 
      "generic_file__based_near_display", 
      "generic_file__tag_display" 
    ],
    :labels => {
      "generic_file__contributor_display"     => "Contributor", 
      "generic_file__creator_display"         => "Creator", 
      "generic_file__title_display"           => "Title", 
      "generic_file__description_display"     => "Description", 
      "generic_file__publisher_display"       => "Publisher", 
      "generic_file__date_created_display"    => "Date Created", 
      "generic_file__date_uploaded_display"   => "Date Uploaded", 
      "generic_file__date_modified_display"   => "Date Modified", 
      "generic_file__subject_display"         => "Subject", 
      "generic_file__language_display"        => "Language", 
      "generic_file__rights_display"          => "Rights", 
      "generic_file__resource_type_display"   => "Resource Type", 
      "generic_file__format_display"          => "Format", 
      "generic_file__identifier_display"      => "Identifier", 
      "generic_file__based_near_display"      => "Location", 
      "generic_file__tag_display"             => "Tag"
    }
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "generic_file__contributor_display", 
      "generic_file__creator_display", 
      "generic_file__title_display", 
      "generic_file__description_display", 
      "generic_file__publisher_display", 
      "generic_file__date_created_display", 
      "generic_file__date_uploaded_display", 
      "generic_file__date_modified_display", 
      "generic_file__subject_display", 
      "generic_file__language_display", 
      "generic_file__rights_display", 
      "generic_file__resource_type_display", 
      "generic_file__format_display", 
      "generic_file__identifier_display", 
      "generic_file__based_near_display", 
      "generic_file__tag_display" 
    ],
    :labels => {
      "generic_file__contributor_display"     => "Contributor", 
      "generic_file__creator_display"         => "Creator", 
      "generic_file__title_display"           => "Title", 
      "generic_file__description_display"     => "Description", 
      "generic_file__publisher_display"       => "Publisher", 
      "generic_file__date_created_display"    => "Date Created", 
      "generic_file__date_uploaded_display"   => "Date Uploaded", 
      "generic_file__date_modified_display"   => "Date Modified", 
      "generic_file__subject_display"         => "Subject", 
      "generic_file__language_display"        => "Language", 
      "generic_file__rights_display"          => "Rights", 
      "generic_file__resource_type_display"   => "Resource Type", 
      "generic_file__format_display"          => "Format", 
      "generic_file__identifier_display"      => "Identifier", 
      "generic_file__based_near_display"      => "Location", 
      "generic_file__tag_display"             => "Tag"
    }
  }


  # "fielded" search configuration. Used by pulldown among other places.
  # For supported keys in hash, see rdoc for Blacklight::SearchFields
  #
  # Search fields will inherit the :qt solr request handler from
  # config[:default_solr_parameters], OR can specify a different one
  # with a :qt key/value. Below examples inherit, except for subject
  # that specifies the same :qt as default for our own internal
  # testing purposes.
  #
  # The :key is what will be used to identify this BL search field internally,
  # as well as in URLs -- so changing it after deployment may break bookmarked
  # urls.  A display label will be automatically calculated from the :key,
  # or can be specified manually to be different. 
  config[:search_fields] ||= []

  # This one uses all the defaults set by the solr request handler. Which
  # solr request handler? The one set in config[:default_solr_parameters][:qt],
  # since we aren't specifying it otherwise. 
  config[:search_fields] << {
    :key => "all_fields",  
    :display_label => 'All Fields'   
  }

  # Now we see how to over-ride Solr request handler defaults, in this
  # case for a BL "search field", which is really a dismax aggregate
  # of Solr search fields. 
  # creator, title, description, publisher, date_created,
  # subject, language, resource_type, format, identifier, based_near,
  config[:search_fields] << {
    :key => 'contributor',     
    # solr_parameters hash are sent to Solr as ordinary url query params. 
    :solr_parameters => {
      :"spellcheck.dictionary" => "contributor"
    },
    # :solr_local_parameters will be sent using Solr LocalParams
    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # Solr parameter de-referencing like $title_qf.
    # See: http://wiki.apache.org/solr/LocalParams
    :solr_local_parameters => {
      :qf => "$contributor_qf",
      :pf => "$contributor_pf"
    }
  }

  config[:search_fields] << {
    :key =>'creator',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "creator" 
    },
    :solr_local_parameters => {
      :qf => "$creator_qf",
      :pf => "$creator_pf"
    }
  }

  config[:search_fields] << {
    :key =>'title',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "title" 
    },
    :solr_local_parameters => {
      :qf => "$title_qf",
      :pf => "$title_pf"
    }
  }

  config[:search_fields] << {
    :key =>'description',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "description" 
    },
    :solr_local_parameters => {
      :qf => "$description_qf",
      :pf => "$description_pf"
    }
  }

  config[:search_fields] << {
    :key =>'publisher',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "publisher" 
    },
    :solr_local_parameters => {
      :qf => "$publisher_qf",
      :pf => "$publisher_pf"
    }
  }

  config[:search_fields] << {
    :key =>'date_created',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "date_created" 
    },
    :solr_local_parameters => {
      :qf => "$date_created_qf",
      :pf => "$date_created_pf"
    }
  }

  config[:search_fields] << {
    :key =>'subject',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "subject" 
    },
    :solr_local_parameters => {
      :qf => "$subject_qf",
      :pf => "$subject_pf"
    }
  }

  config[:search_fields] << {
    :key =>'language',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "language" 
    },
    :solr_local_parameters => {
      :qf => "$language_qf",
      :pf => "$language_pf"
    }
  }

  config[:search_fields] << {
    :key =>'resource_type',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "resource_type" 
    },
    :solr_local_parameters => {
      :qf => "$resource_type_qf",
      :pf => "$resource_type_pf"
    }
  }

  config[:search_fields] << {
    :key =>'format',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "format" 
    },
    :solr_local_parameters => {
      :qf => "$format_qf",
      :pf => "$format_pf"
    }
  }

  config[:search_fields] << {
    :key =>'identifier',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "identifier" 
    },
    :solr_local_parameters => {
      :qf => "$identifier_qf",
      :pf => "$identifier_pf"
    }
  }

  config[:search_fields] << {
    :key =>'based_near',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "based_near" 
    },
    :solr_local_parameters => {
      :qf => "$based_near_qf",
      :pf => "$based_near_pf"
    }
  }

  config[:search_fields] << {
    :key => 'tag', 
    :solr_parameters => {
      :"spellcheck.dictionary" => "tag"
    },
    :solr_local_parameters => {
      :qf => "$tag_qf",
      :pf => "$tag_pf"
    }
  }

  # Specifying a :qt only to show it's possible, and so our internal automated
  # tests can test it. In this case it's the same as 
  # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
  #  config[:search_fields] << {
  #    :key => 'subject', 
  #    :qt=> 'search',
  #    :solr_parameters => {
  #      :"spellcheck.dictionary" => "subject"
  #    },
  #    :solr_local_parameters => {
  #      :qf => "$subject_qf",
  #      :pf => "$subject_pf"
  #    }
  #  }
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields] << ['relevance', 'score desc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['publisher', 'generic_file__publisher_sort asc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['date created', 'generic_file__date_created_sort desc']
  config[:sort_fields] << ['date uploaded', 'generic_file__date_uploaded_sort desc']
  config[:sort_fields] << ['date modified', 'generic_file__date_modified_sort desc']
  #config[:sort_fields] << ['subject', 'generic_file__subject_sort asc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['language', 'generic_file__language_sort asc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['resource_type', 'generic_file__resource_type_sort asc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['format', 'generic_file__format_sort asc, generic_file__date_uploaded_sort desc']
  #config[:sort_fields] << ['tag', 'generic_file__tag_sort asc, generic_file__date_uploaded_sort desc']

  # If there are more than this many search results, no spelling ("did you 
  # mean") suggestion is offered.
  config[:spell_max] = 5

  # Add documents to the list of object formats that are supported for all objects.
  # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats 
  # output; keys are format short-names that can be exported. Hash includes:
  #    :content-type => mime-content-type
  config[:unapi] = {
    'oai_dc_xml' => { :content_type => 'text/xml' } 
  }
end
