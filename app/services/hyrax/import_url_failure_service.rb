module Hyrax
  class ImportUrlFailureService < AbstractMessageService
    def message
      file_set.errors.full_messages.join(', ')
    end

    def subject
      I18n.with_locale(:en) do
        I18n.t('hyrax.notifications.import_url_failure.subject')
      end
    end
  end
end
