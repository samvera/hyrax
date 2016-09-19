module CurationConcerns::WorkBehavior
  extend ActiveSupport::Concern

  include Hydra::Works::WorkBehavior
  include CurationConcerns::HumanReadableType
  include CurationConcerns::Noid
  include CurationConcerns::Permissions
  include CurationConcerns::Serializers
  include Hydra::WithDepositor
  include Solrizer::Common
  include CurationConcerns::HasRepresentative
  include CurationConcerns::WithFileSets
  include CurationConcerns::Naming
  include CurationConcerns::RequiredMetadata
  include CurationConcerns::InAdminSet
  include Hydra::AccessControls::Embargoable
  include GlobalID::Identification
  include CurationConcerns::NestedWorks
  include CurationConcerns::Publishable

  included do
    property :owner, predicate: RDF::URI.new('http://opaquenamespace.org/ns/hydra/owner'), multiple: false
    class_attribute :human_readable_short_description, :indexer
    self.indexer = CurationConcerns::WorkIndexer
  end

  # TODO: this entity should be created by an Actor when the model is created.
  def to_sipity_entity
    raise "Can't create an entity until the model has been persisted" unless persisted?
    @sipity_entity ||= Sipity::Entity.find_or_create_by(proxy_for: to_global_id.to_s,
                                                        workflow: to_sipity_workflow,
                                                        workflow_state: to_sipity_workflow_state)
  end

  # TODO: stub method to create a workflow
  # This tells us which workflow to use.
  def to_sipity_workflow
    @sipity_workflow ||= Sipity::Workflow.find_or_create_by(name: "default-#{model_name.name}")
  end

  # TODO: stub method to create a workflow state
  # This returns the current state.
  def to_sipity_workflow_state
    @sipity_workflow_state ||= Sipity::WorkflowState.find_or_create_by(workflow: to_sipity_workflow,
                                                                       name: 'starting-point')
  end

  module ClassMethods
    # This governs which partial to draw when you render this type of object
    def _to_partial_path #:nodoc:
      @_to_partial_path ||= begin
        element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
        collection = ActiveSupport::Inflector.tableize(name)
        "curation_concerns/#{collection}/#{element}".freeze
      end
    end
  end
end
