# frozen_string_literal: true
require 'active_support/concern'
require 'hyrax/callbacks/registry'

module Hyrax
  module Callbacks
    extend ActiveSupport::Concern

    included do
      # Define class instance variable as endpoint to the
      # Callback::Registry api.
      @callback = Registry.new
    end

    module ClassMethods
      # Reader for class instance variable containing callback definitions.
      def callback
        @callback
      end
    end

    # Accessor to Callback::Registry api for instances.
    def callback
      self.class.callback
    end
  end
end
