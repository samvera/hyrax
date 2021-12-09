# frozen_string_literal: true
RSpec.describe Hyrax::My::WorksSearchBuilder do
  subject(:builder) { described_class.new(scope) }
  let(:me) { FactoryBot.create(:user) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: me) }

  describe "#to_hash" do
    before do
      allow(ActiveFedora::SolrQueryBuilder).to receive(:construct_query_for_rel)
        .with(depositor: me.user_key)
        .and_return("depositor")
    end

    it "filters works that we are the depositor of" do
      expect(builder.to_hash['fq'])
        .to contain_exactly start_with("{!terms f=has_model_ssim}"), "depositor"
    end
  end

  describe ".default_processor_chain" do
    it { expect(described_class.default_processor_chain).to end_with(:filter_models, :show_only_resources_deposited_by_current_user) }
  end
end
