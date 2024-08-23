# frozen_string_literal: true
RSpec.describe Hyrax::Configuration do
  subject(:configuration) { described_class.new }

  describe '#register_roles' do
    it 'yields a RoleRegistry' do
      expect { |b| subject.register_roles(&b) }.to yield_with_args(kind_of(Hyrax::RoleRegistry))
    end
  end
  it { is_expected.to delegate_method(:registered_role?).to(:role_registry) }
  it { is_expected.to delegate_method(:persist_registered_roles!).to(:role_registry) }

  describe '#default_active_workflow_name' do
    subject { described_class.new.default_active_workflow_name }

    it { is_expected.to eq('default') }
  end

  it { is_expected.to respond_to(:active_deposit_agreement_acceptance=) }
  it { is_expected.to respond_to(:active_deposit_agreement_acceptance?) }
  it { is_expected.to respond_to(:activity_to_show_default_seconds_since_now) }
  it { is_expected.to respond_to(:admin_set_class) }
  it { is_expected.to respond_to(:admin_set_model) }
  it { is_expected.to respond_to(:admin_set_model=) }
  it { is_expected.to respond_to(:admin_set_predicate) }
  it { is_expected.to respond_to(:admin_set_predicate=) }
  it { is_expected.to respond_to(:administrative_set_form) }
  it { is_expected.to respond_to(:administrative_set_form=) }
  it { is_expected.to respond_to(:administrative_set_indexer) }
  it { is_expected.to respond_to(:administrative_set_indexer=) }
  it { is_expected.to respond_to(:analytic_start_date) }
  it { is_expected.to respond_to(:analytics?) }
  it { is_expected.to respond_to(:analytics_provider) }
  it { is_expected.to respond_to(:analytics_provider=) }
  it { is_expected.to respond_to(:arkivo_api=) }
  it { is_expected.to respond_to(:system_user_key) }
  it { is_expected.to respond_to(:audit_user_key) }
  it { is_expected.to respond_to(:batch_user_key) }
  it { is_expected.to respond_to(:browse_everything=) }
  it { is_expected.to respond_to(:browse_everything?) }
  it { is_expected.to respond_to(:cache_path) }
  it { is_expected.to respond_to(:citations=) }
  it { is_expected.to respond_to(:collection_class) }
  it { is_expected.to respond_to(:collection_model) }
  it { is_expected.to respond_to(:collection_model=) }
  it { is_expected.to respond_to(:contact_email) }
  it { is_expected.to respond_to(:default_admin_set_id) }
  it { is_expected.to respond_to(:derivative_services) }
  it { is_expected.to respond_to(:derivative_services=) }
  it { is_expected.to respond_to(:display_media_download_link=) }
  it { is_expected.to respond_to(:display_media_download_link?) }
  it { is_expected.to respond_to(:display_microdata?) }
  it { is_expected.to respond_to(:display_share_button_when_not_logged_in=) }
  it { is_expected.to respond_to(:display_share_button_when_not_logged_in?) }
  it { is_expected.to respond_to(:enable_noids?) }
  it { is_expected.to respond_to(:extract_full_text?) }
  it { is_expected.to respond_to(:feature_config_path) }
  it { is_expected.to respond_to(:file_set_form) }
  it { is_expected.to respond_to(:file_set_form=) }
  it { is_expected.to respond_to(:file_set_file_service) }
  it { is_expected.to respond_to(:file_set_file_service=) }
  it { is_expected.to respond_to(:file_set_indexer) }
  it { is_expected.to respond_to(:file_set_indexer=) }
  it { is_expected.to respond_to(:identifier_registrars) }
  it { is_expected.to respond_to(:iiif_image_compliance_level_uri) }
  it { is_expected.to respond_to(:iiif_image_compliance_level_uri=) }
  it { is_expected.to respond_to(:iiif_image_server=) }
  it { is_expected.to respond_to(:iiif_image_server?) }
  it { is_expected.to respond_to(:iiif_image_size_default) }
  it { is_expected.to respond_to(:iiif_image_size_default=) }
  it { is_expected.to respond_to(:iiif_image_url_builder) }
  it { is_expected.to respond_to(:iiif_image_url_builder=) }
  it { is_expected.to respond_to(:iiif_info_url_builder) }
  it { is_expected.to respond_to(:iiif_info_url_builder=) }
  it { is_expected.to respond_to(:iiif_manifest_cache_duration) }
  it { is_expected.to respond_to(:iiif_manifest_cache_duration=) }
  it { is_expected.to respond_to(:iiif_metadata_fields) }
  it { is_expected.to respond_to(:iiif_metadata_fields=) }
  it { is_expected.to respond_to(:libreoffice_path) }
  it { is_expected.to respond_to(:license_service_class) }
  it { is_expected.to respond_to(:license_service_class=) }
  it { is_expected.to respond_to(:logger) }
  it { is_expected.to respond_to(:logger=) }
  it { is_expected.to respond_to(:max_days_between_fixity_checks) }
  it { is_expected.to respond_to(:max_days_between_fixity_checks=) }
  it { is_expected.to respond_to(:max_notifications_for_dashboard) }
  it { is_expected.to respond_to(:owner_permission_levels) }
  it { is_expected.to respond_to(:pcdm_collection_form) }
  it { is_expected.to respond_to(:pcdm_collection_form=) }
  it { is_expected.to respond_to(:pcdm_collection_indexer) }
  it { is_expected.to respond_to(:pcdm_collection_indexer=) }
  it { is_expected.to respond_to(:pcdm_object_form_builder) }
  it { is_expected.to respond_to(:pcdm_object_form_builder=) }
  it { is_expected.to respond_to(:pcdm_object_indexer_builder) }
  it { is_expected.to respond_to(:pcdm_object_indexer_builder=) }
  it { is_expected.to respond_to(:permission_levels) }
  it { is_expected.to respond_to(:permission_options) }
  it { is_expected.to respond_to(:persistent_hostpath) }
  it { is_expected.to respond_to(:realtime_notifications?) }
  it { is_expected.to respond_to(:realtime_notifications=) }
  it { is_expected.to respond_to(:redis_namespace) }
  it { is_expected.to respond_to(:rendering_predicate) }
  it { is_expected.to respond_to(:rendering_predicate=) }
  it { is_expected.to respond_to(:rights_statement_service_class) }
  it { is_expected.to respond_to(:rights_statement_service_class=) }
  it { is_expected.to respond_to(:show_work_item_rows) }
  it { is_expected.to respond_to(:subject_prefix) }
  it { is_expected.to respond_to(:translate_id_to_uri) }
  it { is_expected.to respond_to(:translate_uri_to_id) }
  it { is_expected.to respond_to(:upload_path) }
  it { is_expected.to respond_to(:use_valkyrie?) }
  it { is_expected.to respond_to(:use_valkyrie=) }
  it { is_expected.to respond_to(:registered_ingest_dirs) }
  it { is_expected.to respond_to(:registered_ingest_dirs=) }
  it { is_expected.to respond_to(:range_for_number_of_results_to_display_per_page) }
  it { is_expected.to respond_to(:range_for_number_of_results_to_display_per_page=) }
  it { is_expected.to respond_to(:work_requires_files?) }
  it { is_expected.to respond_to(:simple_schema_loader_config_search_paths) }

  describe "#registered_ingest_dirs" do
    it "provides the Rails tmp directory for temporary downloads for cloud files" do
      expect(configuration.registered_ingest_dirs).to include(Rails.root.join('tmp').to_s)
    end
  end

  describe "#use_valkyrie?" do
    before { stub_const("ENV", "HYRAX_SKIP_WINGS" => "true") }
    it "returns true if wings is disabled" do
      expect(Hyrax.config.use_valkyrie?).to eq true
    end
  end
end
