module Sufia
  class WorkShowPresenter < ::CurationConcerns::WorkShowPresenter
    # delegate fields from Sufia::Works::Metadata to solr_document
    delegate :based_near, :related_url, :depositor, :identifier, :resource_type,
             :keyword, :itemtype, to: :solr_document

    self.file_presenter_class = Sufia::FileSetPresenter

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

    def presenter_types
      CurationConcerns.config.registered_curation_concern_types.map(&:underscore) + ["collection"]
    end

    def grouped_presenters(filtered_by: nil, except: nil)
      grouped = collection_presenters.group_by(&:model_name).transform_keys { |key| key.to_s.underscore }
      grouped.select! { |obj| obj.downcase == filtered_by } unless filtered_by.nil?
      grouped.except!(*except) unless except.nil?
      grouped
    end

    def display_feature_link?
      user_can_feature_works? && solr_document.public? && FeaturedWork.can_create_another? && !featured?
    end

    def display_unfeature_link?
      user_can_feature_works? && solr_document.public? && featured?
    end

    def stats_path
      Sufia::Engine.routes.url_helpers.stats_work_path(self)
    end

    private

      def featured?
        if @featured.nil?
          @featured = FeaturedWork.where(work_id: solr_document.id).exists?
        end
        @featured
      end

      def user_can_feature_works?
        current_ability.can?(:create, FeaturedWork)
      end
  end
end
