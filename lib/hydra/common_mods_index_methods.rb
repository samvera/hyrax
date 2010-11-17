# Provides some helper methods for indexing compound or non-standard facets
#
# == Methods
# 
# extract_person_full_names
#   This method returns an array of Solr::Field objects which combine Lastname, Firstname
# extract_person_organizations
#   This method returns an array of Solr::Field objects which extract the persons affiliation and puts it in an mods_organization_facet

module Hydra::CommonModsIndexMethods
  # Extracts the first and last names of persons and creates Solr::Field objects with for person_full_name_facet
  #
  # == Returns:
  # An array of Solr::Field objects
  #
  def extract_person_full_names
    self.find_by_terms(:person).inject([]) do |names, person|
      name_parts = person.children.inject({}) do |hash,child|
        hash[child.get_attribute(:type)] = child.text if ["family","given"].include? child.get_attribute(:type)
        hash
      end
      names << Solr::Field.new({"person_full_name_facet".to_sym=>[name_parts["family"], name_parts["given"]].join(", ")}) if name_parts.keys == ["family","given"]
      names
    end
  end

  # Extracts the affiliations of persons and creates Solr::Field objects for them
  #
  # == Returns:
  # An array of Solr::Field objects
  #
  def extract_person_organizations
    self.find_by_terms(:person,:affiliation).map { |org| Solr::Field.new({:mods_organization_facet=>org.text}) }
  end
end
