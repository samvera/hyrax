module CurationConcerns
  # Including WithoutNamespace on a controller allows us to prepend the default namespace to the params[:id]
  module WithoutNamespace
    extend ActiveSupport::Concern

    included do
      prepend_before_filter :normalize_identifier, except: [:index, :create, :new]
    end

    protected
      def normalize_identifier
        params[:id] = Sufia::Noid.namespaceize(params[:id])
      end
  end
end
