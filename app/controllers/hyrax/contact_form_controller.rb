# frozen_string_literal: true
module Hyrax
  class ContactFormController < ApplicationController
    before_action :build_contact_form
    layout 'homepage'

    class_attribute :model_class
    self.model_class = Hyrax::ContactForm

    def new; end

    def create
      # not spam and a valid form
      if @contact_form.valid?
        ContactMailer.contact(@contact_form).deliver_now
        flash.now[:notice] = 'Thank you for your message!'
        after_deliver
        @contact_form = model_class.new
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. ' +
                            @contact_form.errors.full_messages.map(&:to_s).join(", ")
      end
      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end

    def handle_create_exception(exception)
      logger.error("Contact form failed to send: #{exception.inspect}")
      flash.now[:error] = 'Sorry, this message was not delivered.'
      render :new
    end

    # Override this method if you want to perform additional operations
    # when a email is successfully sent, such as sending a confirmation
    # response to the user.
    def after_deliver; end

    private

    def build_contact_form
      @contact_form = model_class.new(contact_form_params)
    end

    def contact_form_params
      return {} unless params.key?(:contact_form)
      params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
    end
  end
end
