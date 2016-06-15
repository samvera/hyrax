module Sufia
  class Configuration
    def curation_concerns_config
      @curation_concerns_config ||= CurationConcerns.config
    end

    delegate(*(CurationConcerns.config.methods - Object.methods),
             to: :curation_concerns_config)

    attr_writer :persistent_hostpath
    def persistent_hostpath
      @persistent_hostpath ||= "http://localhost/files/"
    end

    attr_writer :redis_namespace
    def redis_namespace
      @redis_namespace ||= "sufia"
    end

    # TODO: This should move to curation_concerns
    attr_writer :libreoffice_path
    def libreoffice_path
      @libreoffice_path ||= "soffice"
    end

    attr_writer :browse_everything
    def browse_everything
      @browse_everything ||= nil
    end

    attr_writer :analytics
    def analytics
      @analytics ||= false
    end
    attr_writer :citations
    def citations
      @citations ||= false
    end

    attr_writer :max_notifications_for_dashboard
    def max_notifications_for_dashboard
      @max_notifications_for_dashboard ||= 5
    end

    attr_writer :activity_to_show_default_seconds_since_now
    def activity_to_show_default_seconds_since_now
      @activity_to_show_default_seconds_since_now ||= 24 * 60 * 60
    end

    attr_writer :arkivo_api
    def arkivo_api
      @arkivo_api ||= false
    end

    attr_writer :geonames_username
    def geonames_username
      @geonames_username ||= ""
    end

    attr_writer :active_deposit_agreement_acceptance
    def active_deposit_agreement_acceptance
      return true if @active_deposit_agreement_acceptance.nil?
      @active_deposit_agreement_acceptance
    end

    attr_writer :batch_user_key
    def batch_user_key
      @batch_user_key ||= 'batchuser@example.com'
    end

    attr_writer :audit_user_key
    def audit_user_key
      @audit_user_key ||= 'audituser@example.com'
    end

    # TODO: this is called working_path in curation_concerns
    attr_writer :upload_path
    def upload_path
      @upload_path ||= ->() { Rails.root + 'tmp' + 'uploads' }
    end

    # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
    attr_writer :always_display_share_button
    def always_display_share_button
      return true if @always_display_share_button.nil?
      @always_display_share_button
    end

    # Defaulting analytic start date to whenever the file was uploaded by leaving it blank
    attr_writer :analytic_start_date
    attr_reader :analytic_start_date

    attr_writer :display_media_download_link
    def display_media_download_link
      @display_media_download_link ||= false
    end

    attr_writer :permission_levels
    def permission_levels
      @permission_levels ||= { "Choose Access" => "none",
                               "View/Download" => "read",
                               "Edit" => "edit" }
    end

    attr_writer :owner_permission_levels
    def owner_permission_levels
      @owner_permission_levels ||= { "Edit Access" => "edit" }
    end

    # TODO: Delegate to curation_concerns when https://github.com/projecthydra/curation_concerns/pull/848 is merged
    attr_writer :translate_uri_to_id
    def translate_uri_to_id
      @translate_uri_to_id ||= ActiveFedora::Noid.config.translate_uri_to_id
    end

    # TODO: Delegate to curation_concerns when https://github.com/projecthydra/curation_concerns/pull/848 is merged
    attr_writer :translate_id_to_uri
    def translate_id_to_uri
      @translate_id_to_uri ||= ActiveFedora::Noid.config.translate_id_to_uri
    end

    attr_writer :from_email
    def from_email
      @from_email ||= "no-reply@example.org"
    end

    attr_writer :subject_prefix
    def subject_prefix
      @subject_prefix ||= "Contact form:"
    end
  end
end
