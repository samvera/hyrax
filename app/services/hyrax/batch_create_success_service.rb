module Hyrax
  class BatchCreateSuccessService < AbstractMessageService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def message
      I18n.t('hyrax.notifications.batch_create_success.message', user: user)
    end

    def subject
      I18n.t('hyrax.notifications.batch_create_success.subject')
    end
  end
end
