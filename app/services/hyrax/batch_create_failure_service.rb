module Hyrax
  class BatchCreateFailureService < AbstractMessageService
    attr_reader :user, :messages
    def initialize(user, messages)
      @user = user
      @messages = messages.to_sentence
    end

    def message
      I18n.with_locale(:en) do
        I18n.t('hyrax.notifications.batch_create_failure.message', user: user, messages: messages)
      end
    end

    def subject
      I18n.with_locale(:en) do
        I18n.t('hyrax.notifications.batch_create_failure.subject')
      end
    end
  end
end
