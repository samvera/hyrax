require 'spec_helper'
describe Worthwhile::ManagesEmbargoesActor do

  let(:model) {
    Class.new(CurationConcern::BaseActor) {
      include Worthwhile::ManagesEmbargoesActor
    }
  }

  let(:user) { User.new }
  let(:curation_concern) { GenericWork.new(pid: Worthwhile::CurationConcern.mint_a_pid )}
  let(:attributes) {{}}
  subject {
    model.new(curation_concern, user, attributes)
  }
  let(:future_date) { Date.today+2 }

  context "#interpret_visibility" do
    it "should interpret lease and embargo visibility" do
      expect(subject).to receive(:interpret_lease_visibility).and_return(true)
      expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
      expect(subject.interpret_visibility).to be true
    end
    it "should collect failures from interpreting lease & embargo visibility" do
      expect(subject).to receive(:interpret_embargo_visibility).and_return(true)
      expect(subject).to receive(:interpret_lease_visibility).and_return(false)
      expect(subject.interpret_visibility).to be false
    end
  end
  context "#interpret_embargo_visibility" do
    it "should do nothing and return true if visibility is not set to embargo" do
      subject.attributes[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(subject.interpret_embargo_visibility).to be true
    end
    context "when visibility is set to embargo" do
      before do
        subject.attributes[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      end
      it "should apply the embargo remove relevant attributes and return true" do
        subject.attributes[:embargo_release_date] = future_date.to_s
        subject.attributes[:visibility_during_embargo] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.attributes[:visibility_after_embargo] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.curation_concern).to receive(:apply_embargo).with(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(subject.interpret_embargo_visibility).to be true
        expect(subject.attributes[:visibility]).to be_nil
        expect(subject.attributes[:visibility_during_embargo]).to be_nil
        expect(subject.attributes[:visibility_after_embargo]).to be_nil

      end
      it "should set error on curation_concern and return false if embargo_release_date is not set" do
        expect(subject.interpret_embargo_visibility).to be false
        expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "embargo" you must also specify embargo release date.'
      end
    end
  end
  context "#interpret_lease_visibility" do
    it "should do nothing and return true if visibility is not set to embargo" do
      subject.attributes[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(subject.interpret_lease_visibility).to be true
    end
    context "when visibility is set to lease" do
      before do
        subject.attributes[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
      end
      it "should apply the lease, remove relevant attributes and return true" do
        subject.attributes[:lease_expiration_date] = future_date.to_s
        subject.attributes[:visibility_during_lease] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.attributes[:visibility_after_lease] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.curation_concern).to receive(:apply_lease).with(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        expect(subject.interpret_lease_visibility).to be true
        expect(subject.attributes[:visibility]).to eq subject.curation_concern.visibility_during_lease
        expect(subject.attributes[:visibility_during_lease]).to be_nil
        expect(subject.attributes[:visibility_after_lease]).to be_nil
      end
      it "should set error on curation_concern and return false if lease_expiration_date is not set" do
        expect(subject.interpret_lease_visibility).to be false
        expect(subject.curation_concern.errors[:visibility].first).to eq 'When setting visibility to "lease" you must also specify lease expiration date.'
      end
    end
  end
end
