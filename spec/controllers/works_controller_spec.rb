require 'spec_helper'

describe CurationConcerns::GenericWorksController, type: :controller do
  routes { Rails.application.routes }
  let(:user) { create(:user) }
  before { sign_in user }

  describe "#edit" do
    let(:work) {
      GenericWork.create(creator: ["Depeche Mode"], title: ["Strangelog"], language: ['en']) do |gw|
        gw.apply_depositor_metadata(user.email)
      end
    }

    it "allows edit on a work" do
      get :edit, id: work.id
      expect(response).to be_success
    end

    it "prevents edit on a work that still is being processed" do
      allow_any_instance_of(GenericWork).to receive(:processing?).and_return(true)
      expect { get :edit, id: work.id }.to raise_error
    end
  end
end
