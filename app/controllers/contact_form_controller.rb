class ContactFormController < ApplicationController

  def new
    @contact_form = ContactForm.new
  end

  def create
    @contact_form = ContactForm.new(params[:contact_form])
    @contact_form.request = request
    # not spam and a valid form
    if @contact_form.deliver
      flash.now[:notice] = 'Thank you for your message!'
      render :new
    else
      flash[:error] = 'Sorry, this message was not sent successfully. ' 
      flash[:error] << @contact_form.errors.full_messages.map { |s| s.to_s }.join(",")
      render :new
    end
  rescue ScriptError
      flash[:error] = 'Sorry, this message appears to be spam and was not delivered.'
      render :new
  end

end
