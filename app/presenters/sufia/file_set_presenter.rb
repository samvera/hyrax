module Sufia
  class FileSetPresenter < ::CurationConcerns::FileSetPresenter
    include Sufia::CharacterizationBehavior
    include WithEvents

    delegate :depositor, :keyword, :date_created, :date_modified, :itemtype,
             to: :solr_document

    def page_title
      title.first
    end

    def link_name
      current_ability.can?(:read, id) ? page_title : 'File'
    end

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

    def rights
      return if solr_document.rights.nil?
      solr_document.rights.first
    end

    def stats_path
      Sufia::Engine.routes.url_helpers.stats_file_path(self)
    end

    def events(size = 100)
      super(size)
    end

    # This overrides the method in WithEvents
    def event_class
      solr_document.to_model.model_name.name
    end

    def audit_status
      audit_service.logged_audit_status
    end

    def parent
      ids = ActiveFedora::SolrService.query("{!field f=member_ids_ssim}#{id}",
                                            fl: ActiveFedora.id_field)
                                     .map { |x| x.fetch(ActiveFedora.id_field) }
      @parent_presenter ||= CurationConcerns::PresenterFactory.build_presenters(ids,
                                                                                WorkShowPresenter,
                                                                                current_ability).first
    end

    def audit_service
      @audit_service ||= CurationConcerns::FileSetAuditService.new(id)
    end
  end
end
