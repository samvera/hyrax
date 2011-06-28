module Uva
  module ModsIndexMethods
  # extracts the last_name##full_name##computing_id to be used by home view
  def extract_person_full_names_and_computing_ids
    names = {}
    self.find_by_terms(:person).each do |person|
      name_parts = person.children.inject({}) do |hash,child|
        hash[child.get_attribute(:type)] = child.text if ["family","given"].include? child.get_attribute(:type)
        hash["computing_id"] = child.text if child.name == 'computing_id'
        hash
      end
      if name_parts.length == 3 and person.search(:roleTerm).children.text.include?("Author")
        if name_parts["family"].blank? && name_parts["given"].blank? && name_parts["computing_id"].blank?
          value = "Unknown Author"
        else
          value = "#{name_parts["family"]}, #{name_parts["given"]} (#{name_parts["computing_id"]})"
        end
        ::Solrizer::Extractor.insert_solr_field_value(names, "person_full_name_cid_facet", value) if name_parts.length == 3        
      end      
    end
    names
  end
  end
end
