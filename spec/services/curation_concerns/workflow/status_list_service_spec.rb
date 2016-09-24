require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::StatusListService do
  describe "#each" do
    let(:user) { create(:user) }
    let(:service) { described_class.new(user) }
    let(:document) { { id: '33333', has_model_ssim: ['GenericWork'], title_tesim: ['Hey dood!'] } }
    let(:entity) { create(:sipity_entity,
                          proxy_for_global_id: 'gid://internal/GenericWork/33333') }
    before do
      ActiveFedora::SolrService.add(document, commit: true)
      allow(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_entities_for_the_user).and_return([entity])
    end

    let(:results) { service.each.to_a }

    it "returns status rows" do
      expect(results).not_to be_empty
      expect(results.first).to be_kind_of(CurationConcerns::Workflow::StatusListService::StatusRow)
      expect(results.first.document.to_s).to eq 'Hey dood!'
      expect(results.first.state).to eq 'initial'
    end
  end
end
