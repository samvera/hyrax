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

    def events
      @events ||= solr_document.to_model.events(100)
    end

    def audit_status
      audit_service.human_readable_audit_status
    end

    def audit_service
      # model = solr_document.to_model # See https://github.com/projecthydra-labs/hydra-pcdm/issues/197
      model = FileSet.find(id)
      @audit_service ||= CurationConcerns::FileSetAuditService.new(model)
    end
  end
end
