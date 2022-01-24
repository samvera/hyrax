# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::WorksSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user, groups: 'registered') }
  let(:builder) { described_class.new(context) }

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :show_only_managed_works_for_non_admins }
  end

  describe '#discovery_permissions' do
    subject { builder.discovery_permissions }

    it { is_expected.to eq %w[edit read] }
  end

  describe "#show_only_managed_works_for_non_admins" do
    let(:solr_params) { Blacklight::Solr::Request.new }

    before do
      builder.show_only_managed_works_for_non_admins(solr_params)
    end

    it "has filter that excludes depositor" do
      expect(solr_params[:fq]).to eq ["-_query_:\"{!raw f=depositor_ssim}#{user.user_key}\""]
    end

    context "as admin" do
      # Overrides the user sent to builder via context, above.
      let(:user) { create(:user, groups: 'admin') }

      it "does nothing" do
        expect(solr_params[:fq].to_a).to eq []
      end
    end
  end
end
