# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Sufia
  module ContactFormControllerBehavior

  def new
    @contact_form = ContactForm.new
  end

  def create
    @contact_form = ContactForm.new(params[:contact_form])
    @contact_form.request = request
    # not spam and a valid form
    logger.warn "*** MARK ***"
    if @contact_form.deliver
      flash.now[:notice] = 'Thank you for your message!'
      after_deliver
      render :new
    else
      flash[:error] = 'Sorry, this message was not sent successfully. ' 
      flash[:error] << @contact_form.errors.full_messages.map { |s| s.to_s }.join(",")
      render :new
    end
  rescue 
      flash[:error] = 'Sorry, this message was not delivered.'
      render :new
  end

  def after_deliver
     return unless Sufia::Engine.config.enable_contact_form_delivery
  end
  end
end
