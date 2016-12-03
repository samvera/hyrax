require 'active_attr'
module Hyrax
  class ClassifyConcern
    include ActiveAttr::Model
    attribute :curation_concern_type

    validates(
      :curation_concern_type,
      presence: true,
      inclusion: { in: ->(record) { record.registered_curation_concern_types } }
    )

    def all_curation_concern_classes
      registered_curation_concern_types.sort.map { |c| self.class.to_class(c) }
    end

    def registered_curation_concern_types
      Hyrax.config.registered_curation_concern_types
    end

    def possible_curation_concern_types
      registered_curation_concern_types.collect do |concern|
        [self.class.to_class(concern).human_readable_type, concern]
      end
    end

    def curation_concern_class
      if possible_curation_concern_types.detect do |_name, class_name|
        class_name == curation_concern_type
      end
        self.class.to_class(curation_concern_type)
      else
        raise 'Invalid :curation_concern_type'
      end
    end

    # @option [String] type name of the model
    # @return [Class] the model class
    def self.to_class(type)
      type.camelize.constantize
    end
  end
end
