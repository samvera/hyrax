require 'spec_helper'

RSpec.describe CurationConcerns::WorkSearchBuilder do
  let(:me) { create(:user) }
  let(:config) { CatalogController.blacklight_config }
  let(:scope) do
    double('The scope',
           blacklight_config: config,
           current_ability: Ability.new(me),
           current_user: me)
  end
  let(:builder) { described_class.new(scope).with(params) }
  let(:params) { { id: '123abc' } }

  before do
    allow(builder).to receive(:gated_discovery_filters).and_return(["access_filter1", "access_filter2"])

    # This prevents any generated classes from interfering with this test:
    allow(builder).to receive(:work_classes).and_return([GenericWork])
  end

  describe "#query" do
    subject { builder.query }
    let(:doc) { instance_double(SolrDocument) }
    before do
      allow(SolrDocument).to receive(:find).and_return(doc)
    end

    context "when the current_work has a workflow entity" do
      before do
        expect(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_permitted_workflow_actions_available_for_current_state)
          .with(user: me,
                entity: doc).and_return(roles)
      end
      context "and the current user has a role" do
        let(:roles) { [double] }
        it "filters for id, access, suppressed and type" do
          expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                      "{!terms f=has_model_ssim}GenericWork,Collection",
                                      "{!raw f=id}123abc"]
        end
      end
      context "and the current user doesn't have a role" do
        let(:roles) { [] }
        it "filters for id, access, suppressed and type" do
          expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                      "{!terms f=has_model_ssim}GenericWork,Collection",
                                      "-suppressed_bsi:true",
                                      "{!raw f=id}123abc"]
        end
      end
    end

    context "when the current_work doesn't have a workflow entity" do
      before do
        expect(CurationConcerns::Workflow::PermissionQuery).to receive(:scope_permitted_workflow_actions_available_for_current_state)
          .and_raise(PowerConverter::ConversionError.new(double, {}))
      end
      it "filters for id, access, suppressed and type" do
        expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                    "{!terms f=has_model_ssim}GenericWork,Collection",
                                    "-suppressed_bsi:true",
                                    "{!raw f=id}123abc"]
      end
    end
  end
end
