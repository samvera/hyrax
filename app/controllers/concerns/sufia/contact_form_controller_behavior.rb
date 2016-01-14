module Sufia
  module ContactFormControllerBehavior
    def new
      @contact_form = ContactForm.new
    end

    def create
      @contact_form = ContactForm.new(params[:contact_form])
      @contact_form.request = request
      # not spam and a valid form
      if @contact_form.respond_to?(:deliver_now) ? @contact_form.deliver_now : @contact_form.deliver
        flash.now[:notice] = 'Thank you for your message!'
        after_deliver
        @contact_form = ContactForm.new
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. '
        flash.now[:error] << @contact_form.errors.full_messages.map(&:to_s).join(",")
      end
      render :new
    rescue
      flash.now[:error] = 'Sorry, this message was not delivered.'
      render :new
    end

    def after_deliver
      return unless Sufia::Engine.config.enable_contact_form_delivery
    end
  end
end
