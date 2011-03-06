# Stanford SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class HomeController < ActionController::Base
#   
#   include Stanford::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
module Stanford::SolrHelper

  # returns a params hash for a home facet field solr query.
  # used primary by the get_facet_pagination method
  def home_facet_params(extra_controller_params={})
    input = params.deep_merge(extra_controller_params)
    {
      :qt => Blacklight.config[:default_qt],
      :per_page => 0,
      :phrase_filters => input[:f],
      "f.callnum_top_facet.facet.sort" => "false"
    }
  end
  
  # returns a params hash for the advanced search facet field solr query.
  # used primary by the get_facet_pagination method
  def advanced_search_facet_params(extra_controller_params={})
    input = params.deep_merge(extra_controller_params)
    {
      :qt => Blacklight.config[:default_qt],
      :per_page => 0,
      :phrase_filters => input[:f],
      "f.callnum_top_facet.facet.sort" => "false",
      "f.format.facet.sort" => "false",
      "f.building_facet.facet.sort" => "false",
      "f.access_facet.facet.sort" => "false",
      "f.language.facet.limit" => 100
    }
  end
  
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  def get_advanced_search_facets(extra_controller_params={})
    Blacklight.solr.find self.advanced_search_facet_params(extra_controller_params)
  end  
  
  # a solr query method
  # given a user query, return a solr response containing both result docs and facets
  # - mixes in the Blacklight::Solr::SpellingSuggestions module
  #   - the response will have a spelling_suggestions method
  def get_home_facets(extra_controller_params={})
    Blacklight.solr.find self.home_facet_params(extra_controller_params)
  end
  
  # given a field name and a field value, get the next "alphabetic" N 
  #  terms for the field 
  #  returns array of one element hashes with key=term and value=count
  # NOTE:  terms in index are case sensitive!  Okay for shelfkey ...
  def get_next_terms(curr_value, field, how_many)
    # TermsComponent Query to get the terms
    solr_params = {
      'terms.fl' => field,
      'terms.lower' => curr_value,
      :per_page => how_many
    }
    solr_response = Blacklight.solr.send_request('/alphaTerms', solr_params)
    
    # create array of one element hashes with key=term and value=count
    result = []
    terms ||= solr_response['terms'] || []
    field_terms ||= terms[1] || []
    # field_terms is an array of value, then num hits, then next value, then hits ...
    i = 0
    until result.length == how_many || i >= field_terms.length do
      term_hash = {field_terms[i] => field_terms[i+1]}
      result << term_hash
      i = i + 2
    end
    
    result
  end

  # given a field name and array of values, get the matching SOLR documents
  def get_docs_for_field_values(values, field)
    value_str = "(\"" + values.join("\" OR \"") + "\")"
    solr_params = {
      :qt => "standard",   # need boolean for OR
      :q => "#{field}:#{value_str}",
      'fl' => "*",
      'facet' => 'false',
      'spellcheck' => 'false'
    }
    
    solr_response = Blacklight.solr.find solr_params
    solr_response.docs
  end


end
