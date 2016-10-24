require 'spec_helper'

RSpec.describe CurationConcerns::InspectWorkPresenter, no_clean: true do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { "id" => '888888',
      "has_model_ssim" => ["GenericWork"] }
  end

  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:presenter) { described_class.new(solr_document, ability) }
  let(:entity) { instance_double(Sipity::Entity) }

  describe "#workflow" do
    let(:comments) do
      { comment: 'comment', created_at: 'unknown' }
    end
    let(:roles) do
      { id: '1', name: 'reviewing', users: ['user1', 'user2'] }
    end
    before do
      allow(entity).to receive(:id).and_return('1')
      allow(entity).to receive(:workflow_name).and_return('generic_workflow')
      allow(entity).to receive(:workflow_id).and_return('1')
      allow(entity).to receive(:proxy_for_global_id).and_return(attributes["id"])
      allow(entity).to receive(:workflow_id).and_return('1')
      allow(entity).to receive(:workflow_state_id).and_return('1')
      allow(entity).to receive(:workflow_state_name).and_return('completed')
      allow(presenter).to receive(:sipity_entity).and_return(entity)
      allow(presenter).to receive(:workflow_comments).and_return(comments)
      allow(presenter).to receive(:sipity_entity_roles).and_return(roles)
    end

    context "when a valid sipity_entity with workflow exists" do
      subject { presenter.workflow }
      it 'returns a hash of workflow related values for ispection' do
        expect(subject[:entity_id]).to eq '1'
        expect(subject[:workflow_name]).to eq 'generic_workflow'
        expect(subject[:workflow_id]).to eq '1'
        expect(subject[:proxy_for]).to eq attributes["id"]
        expect(subject[:state_id]).to eq '1'
        expect(subject[:state_name]).to eq 'completed'
        expect(subject[:comments][:comment]).to eq 'comment'
        expect(subject[:roles][:id]).to eq '1'
        expect(subject[:roles][:name]).to eq 'reviewing'
        expect(subject[:roles][:users][0]).to eq 'user1'
      end
    end

    context "when no sipity_entity with workflow exists" do
      let(:invalid) { described_class.new('no_solr_document', ability) }
      it "raises PowerConverter::ConversionError" do
        expect { invalid.workflow }.to raise_exception(PowerConverter::ConversionError)
      end
    end
  end
end
