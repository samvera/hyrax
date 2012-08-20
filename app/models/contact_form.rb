class ContactForm < MailForm::Base
  ISSUE_TYPES = [ 
      ["Depositing content", "Depositing content"],
      ["Making changes to my content", "Making changes to my content"],
      ["Browsing and searching", "Browsing and searching"], 
      ["Reporting a problem", "Reporting a problem"],
      ["General inquiry or request", "General inquiry or request"]
    ] 
  attribute :contact_method,  :captcha  => true
  attribute :name,        :validate => true
  attribute :email,       :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message,     :validate => true
  attribute :issue_type,  :validate => true
  # - can't use this without ActiveRecord::Base validates_inclusion_of :issue_type, :in => ISSUE_TYPES

  # Declare the e-mail headers. It accepts anything the mail method
  # in ActionMailer accepts.
  def headers
    {
      :subject => "ScholarSphere Contact Form",
      :to => ScholarSphere::Application.config.contact_email, 
      :from => %("#{name}" <#{email}>)
    }
  end
end
