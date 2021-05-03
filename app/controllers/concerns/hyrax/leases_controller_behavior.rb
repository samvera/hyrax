# frozen_string_literal: true
module Hyrax
  module LeasesControllerBehavior
    extend ActiveSupport::Concern
    include Hyrax::ManagesEmbargoes
    include Hyrax::Collections::AcceptsBatches

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.leases.index.manage_leases'), hyrax.leases_path
      authorize! :index, Hydra::AccessControls::Lease
    end

    # Removes a single lease
    def destroy
      Hyrax::Actors::LeaseActor.new(curation_concern).destroy
      flash[:notice] = curation_concern.lease_history.last
      if curation_concern.work? && curation_concern.file_sets.present?
        redirect_to confirm_permission_path
      else
        redirect_to edit_lease_path
      end
    end

    def update
      filter_docs_with_edit_access!
      copy_visibility = []
      copy_visibility = params[:leases].values.map { |h| h[:copy_visibility] } if params[:leases]
      af_objects = Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: batch, use_valkyrie: Hyrax.config.use_valkryie?)
      af_objects.each do |curation_concern|
        Hyrax::Actors::LeaseActor.new(curation_concern).destroy
        Hyrax::VisibilityPropagator.for(source: curation_concern).propagate if
          copy_visibility.include?(curation_concern.id)
      end
      redirect_to leases_path
    end

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.leases.index.manage_leases'), hyrax.leases_path
      add_breadcrumb t(:'hyrax.leases.edit.lease_update'), '#'
    end
  end
end
