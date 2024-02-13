# frozen_string_literal: true
RSpec.describe Hyrax::WorkSearchBuilder do
  let(:me) { FactoryBot.create(:user) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: me) }
  let(:builder) { described_class.new(scope).with(params) }
  let(:params) { { id: '123abc' } }

  before do
    allow(builder).to receive(:gated_discovery_filters).and_return(["access_filter1", "access_filter2"])

    # This prevents any generated classes from interfering with this test:
    allow(builder).to receive(:work_classes).and_return([Monograph])
  end

  let(:class_filter_string) do
    ([Monograph.to_s] + Hyrax::ModelRegistry.collection_rdf_representations).uniq.join(',')
  end

  describe "#query" do
    subject { builder.query }

    let(:doc) { instance_double(SolrDocument) }

    before do
      allow(SolrDocument).to receive(:find).and_return(doc)
    end

    context "when the current_work has a workflow entity" do
      before do
        expect(Hyrax::Workflow::PermissionQuery).to receive(:scope_permitted_workflow_actions_available_for_current_state)
          .with(user: me,
                entity: doc).and_return(roles)
      end
      context "and the current user has a role" do
        let(:roles) { [double] }

        it "filters for id, access, suppressed and type" do
          expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                      "{!terms f=has_model_ssim}#{class_filter_string}",
                                      "{!raw f=id}123abc"]
        end
      end
      context "and the current user doesn't have a role" do
        let(:roles) { [] }

        context "and the current user is not the depositor" do
          before do
            allow(builder).to receive(:depositor?).and_return(false)
          end

          it "filters for id, access, suppressed and type" do
            expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                        "{!terms f=has_model_ssim}#{class_filter_string}",
                                        "-suppressed_bsi:true",
                                        "{!raw f=id}123abc"]
          end
        end

        context "and the current user is the depositor" do
          before do
            allow(builder).to receive(:depositor?).and_return(true)
          end

          it "filters for id, access, suppressed and type" do
            expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                        "{!terms f=has_model_ssim}#{class_filter_string}",
                                        "{!raw f=id}123abc"]
          end
        end
      end
    end

    context "when the current_work doesn't have a workflow entity" do
      before do
        expect(Hyrax::Workflow::PermissionQuery).to receive(:scope_permitted_workflow_actions_available_for_current_state)
          .and_raise(Sipity::ConversionError.new(double))
      end

      context "and the current user is not the depositor" do
        before do
          allow(builder).to receive(:depositor?).and_return(false)
        end

        it "filters for id, access, suppressed and type" do
          expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                      "{!terms f=has_model_ssim}#{class_filter_string}",
                                      "-suppressed_bsi:true",
                                      "{!raw f=id}123abc"]
        end
      end

      context "and the current user is the depositor" do
        before do
          allow(builder).to receive(:depositor?).and_return(true)
        end

        it "filters for id, access, suppressed and type" do
          expect(subject[:fq]).to eq ["access_filter1 OR access_filter2",
                                      "{!terms f=has_model_ssim}#{class_filter_string}",
                                      "{!raw f=id}123abc"]
        end
      end
    end
  end
end
