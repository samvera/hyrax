# frozen_string_literal: true
module Hyrax
  # Mailer for contacting the administrator
  class ContactMailer < ApplicationMailer
    def contact(contact_form)
      @contact_form = contact_form
      # Check for spam
      return if @contact_form.spam?
      mail(@contact_form.headers)
    end
  end
end
