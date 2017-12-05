module Hyrax
  class ManifestHelper
    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes

    def initialize(hostname)
      @hostname = hostname
    end

    def polymorphic_url(record, opts = {})
      opts[:host] ||= @hostname
      super(record, opts)
    end
  end
end
