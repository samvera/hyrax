module Hydra::ModelMixins
  module SolrDocumentExtension
    extend Deprecation
    self.deprecation_horizon = 'hydra-head 7.0.0'

    def document_type display_type = CatalogController.blacklight_config.show.display_type
      type = self.fetch(:medium_t, nil)

      type ||= self.fetch(display_type, nil) if display_type

      type.first.to_s.gsub("info:fedora/afmodel:","").gsub("Hydrangea","").gsub(/^Generic/,"")
    end
    deprecation_deprecate :document_type

    def get_person_from_role(role, opts={})
      i = 0
      while i < 10
        persons_roles = self["person_#{i}_role_t"].map{|w|w.strip.downcase} unless self["person_#{i}_role_t"].nil?
        if persons_roles and persons_roles.include?(role.downcase)
          return {:first=>self["person_#{i}_first_name_t"], :last=>self["person_#{i}_last_name_t"]}
        end
        i += 1
      end
    end
    deprecation_deprecate :get_person_from_role

    def get_file_asset_count()
      ActiveFedora::Base.count(:conditions=>"is_part_of_t:#{ActiveFedora::Base.quote_for_solr(id)}")
    end
    deprecation_deprecate :get_file_asset_count
  end
end

