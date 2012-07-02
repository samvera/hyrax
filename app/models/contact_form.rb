class ContactForm < MailForm::Base
  attribute :contact_method,  :captcha  => true
  attribute :name,      :validate => true
  attribute :email,     :validate => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i
  attribute :message,   :validate => true

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
