module Sufia
  class MailboxController < ApplicationController
    before_action :authenticate_user!

    def index
      @messages = user_mailbox.inbox
    end

    def delete_all
      user_mailbox.delete_all
      redirect_to sufia.notifications_path, alert: t('sufia.mailbox.notifications_deleted')
    end

    def destroy
      message_id = params[:id]
      alert = user_mailbox.destroy(message_id)
      redirect_to sufia.notifications_path, alert: alert
    end

    private

      def user_mailbox
        UserMailbox.new(current_user)
      end
  end
end
