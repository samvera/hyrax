module Sufia
  class FileSetPresenter < ::CurationConcerns::FileSetPresenter
    delegate :depositor, :tag, :date_created, to: :solr_document

    def tweeter
      user = ::User.find_by_user_key(depositor)
      if user.try(:twitter_handle).present?
        "@#{user.twitter_handle}"
      else
        I18n.translate('sufia.product_twitter_handle')
      end
    end

    # Add a schema.org itemtype
    def itemtype
      # Look up the first non-empty resource type value in a hash from the config
      Sufia.config.resource_types_to_schema[resource_type.to_a.reject(&:empty?).first] || 'http://schema.org/CreativeWork'
    rescue
      'http://schema.org/CreativeWork'
    end
  end
end
