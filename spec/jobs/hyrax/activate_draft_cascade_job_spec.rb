# frozen_string_literal: true

RSpec.describe Hyrax::ActivateDraftCascadeJob do
  def reload(resource)
    Hyrax.query_service.find_by(id: resource.id)
  end

  describe "#perform" do
    context "with a recursive membership tree" do
      # root
      #   ├── file_set_a
      #   └── child ── file_set_b   (grandchild file set)
      let!(:file_set_a) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let!(:file_set_b) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let!(:child)      { FactoryBot.valkyrie_create(:hyrax_work, members: [file_set_b], state: Hyrax::ResourceStatus::INACTIVE) }
      let!(:root)       { FactoryBot.valkyrie_create(:hyrax_work, members: [file_set_a, child], state: Hyrax::ResourceStatus::INACTIVE) }

      before { described_class.perform_now(root.id.to_s, Hyrax::VisibilityIntention::PUBLIC) }

      it "applies the chosen visibility to every member at every depth" do
        expect(reload(file_set_a).visibility).to eq 'open'
        expect(reload(child).visibility).to eq 'open'
        expect(reload(file_set_b).visibility).to eq 'open'
      end

      it "returns child works to the active state so they stop being suppressed" do
        expect(reload(child).state).to eq Hyrax::ResourceStatus::ACTIVE
      end
    end

    context "with a membership cycle" do
      # A genuine A<->B membership cycle cannot be persisted on every backend
      # (Fedora/hydra-pcdm rejects it via AncestorChecker), so stub the member
      # queries to hand the job a cycle and prove the visited-set guard holds.
      let!(:work_a) { FactoryBot.valkyrie_create(:hyrax_work) }
      let!(:work_b) { FactoryBot.valkyrie_create(:hyrax_work) }

      before do
        allow(Hyrax.custom_queries).to receive(:find_child_file_sets).and_return([])
        allow(Hyrax.custom_queries).to receive(:find_child_works) do |resource:|
          resource.id.to_s == work_a.id.to_s ? [work_b] : [work_a]
        end
      end

      it "terminates without infinite recursion and promotes each work once" do
        expect { described_class.perform_now(work_a.id.to_s, 'open') }.not_to raise_error
        expect(reload(work_a).visibility).to eq 'open'
        expect(reload(work_b).visibility).to eq 'open'
      end
    end

    context "when the root cannot be found" do
      it "logs and does not raise" do
        expect { described_class.perform_now('missing-id', 'open') }.not_to raise_error
      end
    end
  end
end
