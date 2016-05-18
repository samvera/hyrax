module Sufia
  class FileSetPresenter < ::CurationConcerns::FileSetPresenter
    include Sufia::CharacterizationBehavior

    delegate :depositor, :keyword, :date_created, :date_modified, :itemtype,
             to: :solr_document

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

    def events
      @events ||= solr_document.to_model.events(100)
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
      # model = solr_document.to_model # See https://github.com/projecthydra-labs/hydra-pcdm/issues/197
      model = FileSet.find(id)
      @audit_service ||= CurationConcerns::FileSetAuditService.new(model)
    end
  end
end
