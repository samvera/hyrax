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
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def update
      filter_docs_with_edit_access!
      copy_visibility = []
      copy_visibility = params[:embargoes].values.map { |h| h[:copy_visibility] } if params[:embargoes]
      resources = Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: batch, use_valkyrie: Hyrax.config.use_valkyrie?)
      resources.each do |resource|
        if Hyrax.config.use_valkyrie?
          EmbargoManager.new(resource: resource).release!
          Hyrax::AccessControlList(resource: resource).save
        else
          Hyrax::Actors::EmbargoActor.new(resource).destroy
          # if the concern is a FileSet, set its visibility and visibility propagation
          if resource.file_set?
            resource.visibility = resource.to_solr["visibility_after_embargo_ssim"]
            resource.save!
          elsif copy_visibility.include?(resource.id)
            Hyrax::VisibilityPropagator.for(source: resource).propagate
          end
        end
        redirect_to embargoes_path, notice: t('.embargo_deactivated')
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

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
