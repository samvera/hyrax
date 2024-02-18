# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           search_state_class: nil)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context, access) }

  describe '#filter_models' do
    before { builder.filter_models(solr_params) }
    let(:access) { :read }
    let(:solr_params) { { fq: [] } }

    it 'adds AdminSet to query' do
      expect(solr_params[:fq].first).to include("{!terms f=has_model_ssim}#{Hyrax::ModelRegistry.admin_set_rdf_representations.join(',')}")
    end
  end

  describe "#gated_discovery_filters" do
    subject { builder.gated_discovery_filters }

    context "when access is :deposit" do
      let(:access) { :deposit }

      context "and user has access" do
        before do
          allow(Hyrax::Collections::PermissionsService).to receive(:source_ids_for_deposit).and_return([7, 8])
        end

        it { is_expected.to eq ["{!terms f=id}7,8"] }
      end

      context "and user has no access" do
        it { is_expected.to eq ["{!terms f=id}"] }
      end
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include(:filter_models, :add_access_controls_to_solr_params) }
  end

  describe "#to_h" do
    subject { builder.to_h }

    context "when searching for read access" do
      before do
        # we just want to look at the user part of the access filters
        allow(ability).to receive(:user_groups).and_return([])
      end
      let(:access) { :read }

      it 'is successful' do
        expect(subject['fq']).to eq ["edit_access_person_ssim:#{user.user_key} OR " \
                                       "discover_access_person_ssim:#{user.user_key} OR " \
                                       "read_access_person_ssim:#{user.user_key}",
                                     "{!terms f=has_model_ssim}#{Hyrax::ModelRegistry.admin_set_rdf_representations.join(',')}"]
      end
    end

    context "when searching for deposit access" do
      let(:access) { :deposit }

      before do
        allow(Hyrax::Collections::PermissionsService).to receive(:source_ids_for_deposit).and_return([7, 8])
      end

      it 'is successful' do
        expect(subject['fq']).to eq ["{!terms f=id}7,8", "{!terms f=has_model_ssim}#{Hyrax::ModelRegistry.admin_set_rdf_representations.join(',')}"]
      end
    end
  end
end
