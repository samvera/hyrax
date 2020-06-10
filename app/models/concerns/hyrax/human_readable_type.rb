# frozen_string_literal: true
module Hyrax
  module HumanReadableType
    extend ActiveSupport::Concern

    module ClassMethods
      def human_readable_type
        I18n.translate("activefedora.models.#{model_name.i18n_key}", default: name.demodulize.titleize)
      end
    end

    def human_readable_type
      self.class.human_readable_type
    end

    def to_solr(solr_doc = {})
      super(solr_doc).tap do |doc|
        doc["human_readable_type_sim"] = human_readable_type
        doc["human_readable_type_tesim"] = human_readable_type
      end
    end
  end
end
