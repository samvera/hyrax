# There is an interplay between an AdminSet and a PermissionTemplate. Given
# that AdminSet is an ActiveFedora::Base and PermissionTemplate is ActiveRecord::Base
# we don't have the usual :has_many or :belongs_to methods to assist in defining that
# relationship. However, from a conceptual standpoint:
#
# * An AdminSet has_one :permission_tempate
# * A PermissionTemplate belongs_to :admin_set
#
# When an object is added as a member of an AdminSet, the AdminSet's associated
# PermissionTemplate is applied to that object (e.g. some of the object's attributes
# are updated as per the rules of the permission template)
#
# @see Hyrax::PermissionTemplate
# @see Hyrax::AdminSetService
# @see Hyrax::Forms::PermissionTemplateForm for validations and creation process
# @see Hyrax::DefaultAdminSetActor
# @see Hyrax::ApplyPermissionTemplateActor
class AdminSet < Valkyrie::Resource
  # include Hydra::AccessControls::WithAccessRight
  include Valkyrie::Resource::AccessControls
  include Hyrax::Noid
  include Hyrax::HumanReadableType

  DEFAULT_ID = 'admin_set/default'.freeze
  DEFAULT_TITLE = ['Default Admin Set'].freeze
  DEFAULT_WORKFLOW_NAME = Hyrax.config.default_active_workflow_name

  # validates_with Hyrax::HasOneTitleValidator
  class_attribute :human_readable_short_description
  # self.indexer = Hyrax::AdminSetIndexer
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :description, Valkyrie::Types::Set
  attribute :creator, Valkyrie::Types::Set
  attribute :thumbnail_id, Valkyrie::Types::SingleValuedString.optional

  # property :title, predicate: ::RDF::Vocab::DC.title do |index|
  #   index.as :stored_searchable, :facetable
  # end
  # property :description, predicate: ::RDF::Vocab::DC.description do |index|
  #   index.as :stored_searchable
  # end
  #
  # property :creator, predicate: ::RDF::Vocab::DC11.creator do |index|
  #   index.as :symbol
  # end

  # has_many :members,
  #          predicate: Hyrax.config.admin_set_predicate,
  #          class_name: 'ActiveFedora::Base'

  # before_destroy :check_if_not_default_set, :check_if_empty
  # after_destroy :destroy_permission_template

  def self.default_set?(id)
    id.to_s == DEFAULT_ID
  end

  def default_set?
    self.class.default_set?(id)
  end

  # Creates the default AdminSet and an associated PermissionTemplate with workflow
  def self.find_or_create_default_admin_set_id
    unless Hyrax::Queries.exists?(Valkyrie::ID.new(DEFAULT_ID))
      Hyrax::AdminSetCreateService.create_default_admin_set(admin_set_id: DEFAULT_ID, title: DEFAULT_TITLE)
    end
    DEFAULT_ID
  end

  def to_s
    title.present? ? title : 'No Title'
  end

  def members
    query_service.find_inverse_references_by(resource: self, property: :admin_set_id)
  end

  # @api public
  # A bit of an analogue for a `has_one :admin_set` as it crosses from Fedora to the DB
  # @return [Hyrax::PermissionTemplate]
  # @raise [ActiveRecord::RecordNotFound]
  def permission_template
    Hyrax::PermissionTemplate.find_by!(admin_set_id: id.to_s)
  end

  # @api public
  #
  # @return [Sipity::Workflow]
  # @raise [ActiveRecord::RecordNotFound]
  def active_workflow
    Sipity::Workflow.find_active_workflow_for(admin_set_id: id)
  end

  # Calculate and update who should have edit access based on who
  # has "manage" access in the PermissionTemplateAccess
  def update_access_controls!
    update!(edit_users: permission_template.agent_ids_for(access: 'manage', agent_type: 'user'),
            edit_groups: permission_template.agent_ids_for(access: 'manage', agent_type: 'group'))
  end

  private

    def query_service
      Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    end
end
