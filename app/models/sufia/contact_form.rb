module Sufia
  class ContactForm
    include ActiveModel::Model
    ISSUE_TYPES = [
      ["Depositing content", "Depositing content"],
      ["Making changes to my content", "Making changes to my content"],
      ["Browsing and searching", "Browsing and searching"],
      ["Reporting a problem", "Reporting a problem"],
      ["General inquiry or request", "General inquiry or request"]
    ].freeze

    attr_accessor :contact_method, :category, :name, :email, :subject, :message
    validates :email, :category, :name, :subject, :message, presence: true
    validates :email, format: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, allow_blank: true

    # - can't use this without ActiveRecord::Base validates_inclusion_of :category, in: ISSUE_TYPES

    # They should not have filled out the `contact_method' field. That's there to prevent spam.
    def spam?
      contact_method.present?
    end

    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    def headers
      {
        subject: "#{Sufia.config.subject_prefix} #{subject}",
        to: Sufia.config.contact_email,
        from: email
      }
    end
  end
end
