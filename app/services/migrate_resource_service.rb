# frozen_string_literal: true

# migrates models from AF to valkyrie
class MigrateResourceService
  attr_accessor :resource
  def initialize(resource:)
    @resource = resource
  end

  def model
    @model || Wings::ModelRegistry.lookup(resource.class).to_s
  end

  def call
    prep_resource
    Hyrax::Transactions::Container[model_events(model)]
      .with_step_args(**model_steps(model)).call(resource_form)
  end

  def prep_resource
    case model
    when 'FileSet'
      resource.creator << ::User.batch_user.email if resource.creator.blank?
    end
  end

  def resource_form
    @resource_form ||= Hyrax::Forms::ResourceForm.for(resource: resource)
  end

  def model_events(model)
    {
      'AdminSet' => 'admin_set_resource.update',
      'Collection' => 'change_set.update_collection',
      'FileSet' => 'change_set.update_file_set'
    }[model] || 'change_set.update_work'
  end

  def model_steps(model)
    {
      'AdminSet' => {},
      'Collection' => {
        'collection_resource.save_collection_banner' => { banner_unchanged_indicator: true },
        'collection_resource.save_collection_logo' => { logo_unchanged_indicator: true }
      },
      'FileSet' => {
        'file_set.save_acl' => {}
      }
    }[model] || {
      'work_resource.add_file_sets' => { uploaded_files: [], file_set_params: [] },
      'work_resource.update_work_members' => { work_members_attributes: [] },
      'work_resource.save_acl' => { permissions_params: [] }
    }
  end
end
