class BatchController < ApplicationController
  include Hydra::Controller::ControllerBehavior
  layout "sufia-one-column"

  before_filter :has_access?
  prepend_before_filter :normalize_identifier, only: [:edit, :show, :update, :destroy]

  def edit
    @batch =  Batch.find_or_create(params[:id])
    @generic_file = GenericFile.new
    @generic_file.creator = current_user.name
    @generic_file.title = @batch.generic_files.map(&:label)
    @generic_file.initialize_fields
  end

  def update
    authenticate_user!
    @batch = Batch.find_or_create(params[:id])
    @batch.status="processing"
    @batch.save
    Sufia.queue.push(BatchUpdateJob.new(current_user.user_key, params))
    flash[:notice] = 'Your files are being processed by ' + t('sufia.product_name') + ' in the background. The metadata and access controls you specified are being applied. Files will be marked <span class="label label-danger" title="Private">Private</span> until this process is complete (shouldn\'t take too long, hang in there!). You may need to refresh your dashboard to see these updates.'
    redirect_to sufia.dashboard_files_path
  end

  protected

  # override this method if you need to initialize more complex RDF assertions (b-nodes)
  def initialize_fields(file)
    file.initialize_fields
  end

  ActiveSupport::Deprecation.deprecate_methods(BatchController, :initialize_fields)
end
