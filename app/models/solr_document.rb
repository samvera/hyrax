# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document

  def title_or_label
    self['generic_file__title_display'] ? 'generic_file__title_display' : 'label_t'
  end

  # self.unique_key = 'id'

  # The following shows how to setup this blacklight document to display marc documents
  #extension_parameters[:marc_source_field] = :marc_display
  #extension_parameters[:marc_format_type] = :marcxml
  #use_extension(Blacklight::Solr::Document::Marc) do |document|
  #  document.key? :marc_display
  #end

  # Email uses the semantic field mappings below to generate the body of an email.
  #use_extension(Blacklight::Solr::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  #use_extension(Blacklight::Solr::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  #use_extension( Blacklight::Solr::Document::DublinCore)
  #field_semantics.merge!(
  #                       :title => "title_display",
  #                       :author => "author_display",
  #                       :language => "language_facet",
  #                       :format => "format"
  #                       )
end
