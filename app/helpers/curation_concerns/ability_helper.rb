module CurationConcerns
  module AbilityHelper
    # Returns true if can create at least one type of work
    def can_ever_create_works?
      can = false
      CurationConcerns.configuration.curation_concerns.each do |curation_concern_type|
        break if can
        can = can?(:create,curation_concern_type)
      end
      return can
    end

    def visibility_options(variant)
      options = [
          ['Open Access',Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC],
          [t('sufia.institution_name'),Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED],
          ['Private',Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
      ]
      case variant
        when :restrict
          options.delete_at(0)
          options.reverse!
        when :loosen
          options.delete_at(2)
      end
      return options
    end

    def visibility_badge(value)
      case value
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          content_tag :span, "Open Access", class:"label label-success"
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          content_tag :span, t('sufia.institution_name'), class:"label label-info"
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          content_tag :span, "Private", class:"label label-danger"
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
          content_tag :span, "Embargo", class:"label label-warning"
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
          content_tag :span, "Lease", class:"label label-warning"
        else
          content_tag :span, value, class:"label label-info"
      end
    end
  end
end