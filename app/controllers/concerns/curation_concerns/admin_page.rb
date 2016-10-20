module CurationConcerns
  module AdminPage
    extend ActiveSupport::Concern

    included do
      cattr_accessor :configuration
      self.configuration = CurationConcerns.config.dashboard_configuration
      before_action :load_configuration
      layout "admin"
    end

    private

      def load_configuration
        @configuration = self.class.configuration.with_indifferent_access
      end
  end
end
