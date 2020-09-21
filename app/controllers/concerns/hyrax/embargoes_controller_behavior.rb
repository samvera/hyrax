# frozen_string_literal: true
module Hyrax
  module EmbargoesControllerBehavior
    extend ActiveSupport::Concern
    include Hyrax::ManagesEmbargoes
    include Hyrax::Collections::AcceptsBatches

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.embargoes.index.manage_embargoes'), hyrax.embargoes_path
      authorize! :index, Hydra::AccessControls::Embargo
    end

    # Removes a single embargo
    def destroy
      Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
      flash[:notice] = curation_concern.embargo_history.last
      if curation_concern.work? && curation_concern.file_sets.present?
        redirect_to confirm_permission_path
      else
        redirect_to edit_embargo_path
      end
    end

    # Updates a batch of embargos
    def update
      filter_docs_with_edit_access!
      copy_visibility = []
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] } if params[:embargoes]
      af_objects = Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: batch, use_valkyrie: Hyrax.config.use_valkyrie?)
      af_objects.each do |curation_concern|
        Hyrax::Actors::EmbargoActor.new(curation_concern).destroy
        # if the concern is a FileSet, set its visibility and visibility propagation
        if curation_concern.file_set?
          curation_concern.visibility = curation_concern.to_solr["visibility_after_embargo_ssim"]
          curation_concern.save!
        elsif copy_visibility.include?(curation_concern.id)
          Hyrax::VisibilityPropagator.for(source: curation_concern).propagate
        end
      end
      redirect_to embargoes_path, notice: t('.embargo_deactivated')
    end

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.embargoes.index.manage_embargoes'), hyrax.embargoes_path
      add_breadcrumb t(:'hyrax.embargoes.edit.embargo_update'), '#'
    end
  end
end
