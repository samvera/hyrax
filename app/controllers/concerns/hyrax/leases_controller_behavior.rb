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
      flash[:notice] = lease_history(curation_concern)&.last
      if curation_concern.work? && work_has_file_set_members?(curation_concern)
        redirect_to confirm_permission_path
      else
        redirect_to edit_lease_path
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def update
      filter_docs_with_edit_access!
      copy_visibility = []
      copy_visibility = params[:leases].values.map { |h| h[:copy_visibility] } if params[:leases]
      resources = Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: batch, use_valkyrie: Hyrax.config.use_valkyrie?)
      resources.each do |resource|
        if Hyrax.config.use_valkyrie?
          LeaseManager.new(resource: resource).release!
          Hyrax::AccessControlList(resource).save
        else
          Hyrax::Actors::LeaseActor.new(resource).destroy
        end
        Hyrax::VisibilityPropagator.for(source: resource).propagate if
          copy_visibility.include?(resource.id)
      end
      redirect_to leases_path
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # This allows us to use the unauthorized template in curation_concerns/base
    def self.local_prefixes
      ['hyrax/base']
    end

    def edit
      @curation_concern = Hyrax::Forms::WorkLeaseForm.new(curation_concern).prepopulate! if
        Hyrax.config.use_valkyrie?
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.leases.index.manage_leases'), hyrax.leases_path
      add_breadcrumb t(:'hyrax.leases.edit.lease_update'), '#'
    end

    private

    def lease_history(concern)
      concern.try(:lease_history) ||
        concern.try(:lease)&.lease_history
    end
  end
end
