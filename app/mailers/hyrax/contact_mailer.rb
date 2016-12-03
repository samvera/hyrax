module Hyrax
  # Mailer for contacting the administrator
  class ContactMailer < ActionMailer::Base
    def contact(contact_form)
      @contact_form = contact_form
      # Check for spam
      return if @contact_form.spam?
      mail(@contact_form.headers)
    end
  end
end
