# frozen_string_literal: true

# This module handles the setup of flexible metadata for the test suite.
# It's extracted from spec_helper.rb to improve organization and maintainability.
module FlexibleMetadataSetup
  class << self
    def setup_flexible_metadata
      return unless Hyrax.config.flexible?

      register_engine_base_classes
      create_flexible_schema
      setup_acts_as_flexible_resource
      reinitialize_app_level_models
      cleanup_registered_concerns
      reinitialize_indexers
      reinitialize_forms

      puts "Flexible schema setup complete"
    end

    private

    def register_engine_base_classes
      # Register engine base classes as curation concerns and in flexible_classes
      # so FlexibleSchema profile validation passes. The validator checks that
      # all profile classes are in registered_curation_concern_types.
      Hyrax.config.register_curation_concern("hyrax/work")
      Hyrax.config.register_curation_concern("hyrax/pcdm_collection")
      Hyrax.config.register_curation_concern("hyrax/test/simple_work")
      Hyrax.config.register_curation_concern("hyrax/file_set")

      %w[Hyrax::Work Hyrax::PcdmCollection Hyrax::FileSet Hyrax::Test::SimpleWork].each do |klass|
        Hyrax.config.flexible_classes << klass unless Hyrax.config.flexible_classes.include?(klass)
      end
    end

    def create_flexible_schema
      @flexible_schema = Hyrax::FlexibleSchema.create do |f|
        f.profile = YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile-allinson.yaml'))
      end
    end

    def setup_acts_as_flexible_resource
      # Set up flexible metadata for engine base classes used in specs.
      # Must happen after FlexibleSchema.create so the schema record exists
      # when Hyrax::Schema loads attributes from the database.
      [Hyrax::Work, Hyrax::PcdmCollection, Hyrax::FileSet, Hyrax::Test::SimpleWork].each(&:acts_as_flexible_resource)
    end

    def reinitialize_app_level_models
      # Also re-initialize app-level model classes. Their inherited() callback
      # ran during class definition (app boot), before the FlexibleSchema existed
      # in the DB. At that time, the M3SchemaLoader fell back to a default schema
      # missing app-specific attributes (e.g. record_info for Monograph).
      # Re-calling acts_as_flexible_resource now loads the real profile.
      [Monograph, GenericWork, CollectionResource].each(&:acts_as_flexible_resource)
    end

    def cleanup_registered_concerns
      # Unregister engine base classes from curation concerns now that schema
      # validation has passed. Keeping them registered causes routing errors:
      # new_polymorphic_path(Hyrax::Work) tries to generate new_hyrax_work_path
      # which doesn't exist, crashing any page with the work type modal.
      # They remain in flexible_classes for metadata purposes.
      %w[hyrax/work hyrax/pcdm_collection hyrax/test/simple_work hyrax/file_set].each do |concern|
        Hyrax.config.instance_variable_get(:@registered_concerns).delete(concern)
      end
    end

    def reinitialize_indexers
      # Re-run check_if_flexible on indexer classes that may have been loaded
      # before the acts_as_flexible_resource calls above. When RSpec loads spec
      # files, class references in describe blocks trigger autoloading of indexer
      # classes. Their class bodies evaluate check_if_flexible() at that point,
      # but the model classes are not yet flexible (acts_as_flexible_resource
      # has not run). This retroactively includes the M3SchemaLoader indexer
      # module for any indexer that missed it.
      indexer_model_pairs.each do |indexer_class, model_class|
        has_flexible = indexer_class.ancestors.any? do |a|
          a.is_a?(Hyrax::Indexer) && a.index_loader.is_a?(Hyrax::M3SchemaLoader)
        rescue StandardError
          false
        end
        indexer_class.check_if_flexible(model_class) unless has_flexible
      end
    end

    def reinitialize_forms
      # Re-run check_if_flexible on form classes that may have been loaded
      # before acts_as_flexible_resource. Same timing issue as indexers.
      form_model_pairs.each do |form_class, model_class|
        form_class.check_if_flexible(model_class) unless form_class.ancestors.include?(Hyrax::FlexibleFormBehavior)
      end
    end

    def indexer_model_pairs
      [
        [Hyrax::Indexers::PcdmCollectionIndexer, Hyrax::PcdmCollection],
        [Hyrax::Indexers::FileSetIndexer, Hyrax::FileSet],
        [Hyrax::Indexers::AdministrativeSetIndexer, Hyrax::AdministrativeSet],
        [MonographIndexer, Monograph],
        [GenericWorkIndexer, GenericWork]
      ]
    end

    def form_model_pairs
      [
        [Hyrax::Forms::PcdmCollectionForm, Hyrax::PcdmCollection],
        [Hyrax::Forms::FileSetForm, Hyrax::FileSet],
        [Hyrax::Forms::AdministrativeSetForm, Hyrax::AdministrativeSet],
        [MonographForm, Monograph],
        [GenericWorkForm, GenericWork]
      ]
    end
  end
end
