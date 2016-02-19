module Sufia
  class FileSetPresenter < ::CurationConcerns::FileSetPresenter
    include Sufia::CharacterizationBehavior

    delegate :depositor, :tag, :date_created, :date_modified, to: :solr_document

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

    def related_files
      # TODO: support related_files. Maybe.
      # See https://github.com/projecthydra/sufia/issues/1478
      []
    end

    # Add a schema.org itemtype
    def itemtype
      # Look up the first non-empty resource type value in a hash from the config
      Sufia.config.resource_types_to_schema[resource_type.to_a.reject(&:empty?).first] || 'http://schema.org/CreativeWork'
    rescue
      'http://schema.org/CreativeWork'
    end

    def processing?
      # TODO: Refactor this away per https://github.com/projecthydra/sufia/pull/1592
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

    def audit_service
      # model = solr_document.to_model # See https://github.com/projecthydra-labs/hydra-pcdm/issues/197
      model = FileSet.find(id)
      @audit_service ||= CurationConcerns::FileSetAuditService.new(model)
    end
  end
end
