class BatchController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  layout "sufia-one-column"

  before_filter :has_access?
  prepend_before_filter :normalize_identifier, only: [:edit, :show, :update, :destroy]

  def edit
    @batch = Batch.find_or_create(params[:id])
    @form = edit_form
  end

  def update
    authenticate_user!
    @batch = Batch.find_or_create(params[:id])
    @batch.status = ["processing"]
    @batch.save
    file_attributes = Sufia::Forms::BatchEditForm.model_attributes(params[:generic_file])
    Sufia.queue.push(BatchUpdateJob.new(current_user.user_key, params[:id], params[:title], file_attributes, params[:visibility]))
    flash[:notice] = 'Your files are being processed by ' + t('sufia.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-danger" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'
    redirect_to sufia.dashboard_files_path
  end

  protected

  def edit_form
    generic_file = GenericFile.new(creator: [current_user.name], title: @batch.generic_files.map(&:label))
    Sufia::Forms::BatchEditForm.new(generic_file)
  end

  # override this method if you need to initialize more complex RDF assertions (b-nodes)
  def initialize_fields(file)
    file.initialize_fields
  end

  ActiveSupport::Deprecation.deprecate_methods(BatchController, :initialize_fields)
end
