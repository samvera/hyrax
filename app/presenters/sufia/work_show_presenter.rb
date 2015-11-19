module Sufia
  class WorkShowPresenter < ::CurationConcerns::WorkShowPresenter
    def tweeter
      user = ::User.find_by_user_key(model.depositor)
      if user.try(:twitter_handle).present?
        "@#{user.twitter_handle}"
      else
        I18n.translate('sufia.product_twitter_handle')
      end
    end

    # Add a schema.org itemtype
    def itemtype
      # Look up the first non-empty resource type value in a hash from the config
      resource_type = solr_document.resource_type.to_a.reject(&:empty?).first
      Sufia.config.resource_types_to_schema[resource_type] || 'http://schema.org/CreativeWork'
    rescue
      'http://schema.org/CreativeWork'
    end
  end
end
