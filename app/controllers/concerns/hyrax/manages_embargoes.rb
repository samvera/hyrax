# frozen_string_literal: true
module Hyrax
  module ManagesEmbargoes
    extend ActiveSupport::Concern

    included do
      attr_accessor :curation_concern
      helper_method :curation_concern
      base_class = Hyrax.config.use_valkyrie? ? Hyrax::Resource : ActiveFedora::Base
      load_and_authorize_resource class: base_class, instance_name: :curation_concern, except: [:index]
    end

    # This is an override of Hyrax::ApplicationController
    def deny_access(exception)
      redirect_to root_path, alert: exception.message
    end

    def edit; end
  end
end
