module Sufia
  class WorkShowPresenter < ::CurationConcerns::WorkShowPresenter
    # delegate fields from Sufia::Works::Metadata to solr_document
    delegate :based_near, :related_url, :depositor, :identifier, :resource_type, :tag, to: :solr_document

    def editor?
      current_ability.can?(:edit, solr_document)
    end

    def tweeter
      user = ::User.find_by_user_key(depositor)
      if user.try(:twitter_handle).present?
        "@#{user.twitter_handle}"
      else
        I18n.translate('sufia.product_twitter_handle')
      end
    end

    def display_feature_link?
      user_can_feature_works? && solr_document.public? && FeaturedWork.can_create_another? && !featured?
    end

    def display_unfeature_link?
      user_can_feature_works? && solr_document.public? && featured?
    end

    # Add a schema.org itemtype
    def itemtype
      # Look up the first non-empty resource type value in a hash from the config
      resource_type = solr_document.resource_type.to_a.reject(&:empty?).first
      Sufia.config.resource_types_to_schema[resource_type] || 'http://schema.org/CreativeWork'
    rescue
      'http://schema.org/CreativeWork'
    end

    def processing?
      # TODO: Do we need to collect and summarize procesing of attached files?
      false
    end

    def stats_path
      Sufia::Engine.routes.url_helpers.stats_work_path(self)
    end

    private

      def featured?
        if @featured.nil?
          @featured = FeaturedWork.where(generic_work_id: solr_document.id).exists?
        end
        @featured
      end

      def user_can_feature_works?
        current_ability.can?(:create, FeaturedWork)
      end
  end
end
