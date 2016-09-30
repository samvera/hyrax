require 'spec_helper'

RSpec.describe CurationConcerns::WorkflowPresenter, no_clean: true do
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { "id" => '888888',
      "has_model_ssim" => ["GenericWork"] }
  end

  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:presenter) { described_class.new(solr_document, ability) }
  let(:entity) { instance_double(Sipity::Entity) }

  describe "#actions" do
    let(:workflow) { create(:workflow, name: 'testing') }
    before do
      allow(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_permitted_workflow_actions_available_for_current_state).and_return([Sipity::WorkflowAction.new(name: "complete", workflow: workflow)])
      allow(presenter).to receive(:sipity_entity).and_return(entity)
    end

    subject { presenter.actions }
    it "is an Array of Sipity::Action#name and translated names" do
      allow(I18n).to receive(:t).with('curation_concerns.workflow.testing.complete', default: 'Complete').and_return("Approve")
      is_expected.to eq [['complete', 'Approve']]
    end
  end

  describe "#comments" do
    let(:comment) { instance_double(Sipity::Comment) }
    before do
      allow(entity).to receive(:comments).and_return([comment])
      allow(presenter).to receive(:sipity_entity).and_return(entity)
    end

    subject { presenter.comments }
    it { is_expected.to eq [comment] }
  end
end
