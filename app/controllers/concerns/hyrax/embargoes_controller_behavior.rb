module Hyrax
  module EmbargoesControllerBehavior
    extend ActiveSupport::Concern
    include Hyrax::ManagesEmbargoes
    include Hyrax::Collections::AcceptsBatches

    def index
      authorize! :index, Hydra::AccessControls::Embargo
    end

    # Removes a single embargo
    def destroy
      @curation_concern = find_resource(params[:id])
      authorize! :destroy, @curation_concern
      embargo = Hyrax::Actors::EmbargoActor.new(@curation_concern).destroy
      flash[:notice] = embargo.embargo_history.last
      if @curation_concern.work? && @curation_concern.file_sets.present?
        redirect_to confirm_permission_path
      else
        redirect_to edit_embargo_path
      end
    end

    # Updates a batch of embargos
    def update
      filter_docs_with_edit_access!
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] }
      batch.each do |id|
        curation_concern = find_resource(id)
        Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
        curation_concern.copy_visibility_to_files if copy_visibility.include?(id)
      end
      redirect_to embargoes_path
    end

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end
  end
end
