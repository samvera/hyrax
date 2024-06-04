# frozen_string_literal: true

module Hyrax
  ##
  # There are four conceptual high-level models for the metadata modeling:
  #
  # - AdminSet :: Where things are "physically" stored.
  # - Collection :: What things "logically" belong to.
  # - Work :: What the thing is about; these are often sub-divided into different work types
  #   (e.g. an Article, a Monograph, etc.)
  # - FileSet :: Artifacts that further describe the thing.
  #
  # The purpose of this module is to provide an overview and map of the modeling concepts.  This is
  # envisioned as a module to interrogate to see how Hyrax conceptually organizes your models.
  #
  # For each of the above high-level models the {Hyrax::ModelRegistry} implements two methods:
  #
  # - <model_type>_classes :: These are the Ruby constants that represent the conceptual models.
  # - <model_type>_rdf_representations :: These are the stored strings that help us describe what #
  # - the data models.  Very useful in our Solr queries when we want to filter/query on the
  # - "has_model_ssim" attribute.
  #
  # Consider that an {AdminSet} and a {Hyrax::AdministrativeSet} conceptually model the same thing;
  # the latter implements via Valkyrie and the former via ActiveFedora.
  #
  # @note Due to the shift from ActiveFedora to Valkyrie, we are at a crossroads where we might have
  # multiple models for the versions: an ActiveFedora AdminSet and a Valkyrie AdminSet.
  class ModelRegistry
    ##
    # @return [Array<String>]
    def self.admin_set_class_names
      ["::AdminSet", "::Hyrax::AdministrativeSet", Hyrax.config.admin_set_model].uniq
    end

    ##
    # @return [Array<Class>]
    def self.admin_set_classes
      classes_from(admin_set_class_names)
    end

    ##
    # @return [Array<String>]
    def self.admin_set_rdf_representations
      rdf_representations_from(admin_set_classes)
    end

    ##
    # @return [Array<String>]
    def self.collection_class_names
      ["::Collection", "::Hyrax::PcdmCollection", Hyrax.config.collection_model].uniq
    end

    ##
    # @return [Array<String>]
    def self.collection_classes
      classes_from(collection_class_names)
    end

    def self.collection_rdf_representations
      rdf_representations_from(collection_classes)
    end

    def self.collection_has_model_ssim
      collection_rdf_representations
    end

    ##
    # @return [Array<String>]
    def self.file_set_class_names
      ["::FileSet", "::Hyrax::FileSet", Hyrax.config.file_set_model].uniq
    end

    def self.file_set_classes
      classes_from(file_set_class_names)
    end

    ##
    # @return [Array<String>]
    def self.file_set_rdf_representations
      rdf_representations_from(file_set_classes)
    end

    ##
    # @return [Array<Class>]
    #
    # @todo Consider the Wings::ModelRegistry and how we perform mappings.
    def self.work_class_names
      @work_class_names ||= (Hyrax.config.registered_curation_concern_types +
        Array(Rails.application.class.try(:work_types))).map(&:to_s).uniq
    end

    def self.work_classes
      classes_from(work_class_names)
    end

    ##
    # @return [Array<String>]
    def self.work_rdf_representations
      rdf_representations_from(work_classes)
    end

    def self.classes_from(strings)
      strings.map(&:safe_constantize).compact.uniq
    end

    def self.rdf_representations_from(klasses)
      klasses.map { |klass| klass.respond_to?(:to_rdf_representation) ? klass.to_rdf_representation : klass.name }.uniq
    end
  end
end
