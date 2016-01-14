require 'mail_form'

class ContactForm < MailForm::Base
  ISSUE_TYPES = [
    ["Depositing content", "Depositing content"],
    ["Making changes to my content", "Making changes to my content"],
    ["Browsing and searching", "Browsing and searching"],
    ["Reporting a problem", "Reporting a problem"],
    ["General inquiry or request", "General inquiry or request"]
  ].freeze
  attribute :contact_method, captcha: true
  attribute :category, validate: true
  attribute :name, validate: true
  attribute :email, validate: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :subject, validate: true
  attribute :message, validate: true
  # - can't use this without ActiveRecord::Base validates_inclusion_of :issue_type, in: ISSUE_TYPES

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    {
      subject: "Contact Form:#{subject}",
      to: Sufia.config.contact_email,
      from: Sufia.config.from_email
    }
  end
end
