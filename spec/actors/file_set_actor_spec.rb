require 'spec_helper'

describe Sufia::FileSetActor do
  include ActionDispatch::TestProcess

  let(:user) { create(:user) }
  let(:file_set) { create(:file_set) }
  let(:actor) { described_class.new(file_set, user) }

  describe 'creating metadata and content' do
    let(:date_today)    { DateTime.now }
    let(:upload_set_id) { "upload_id" }
    subject { file_set.reload }
    context "when no work is provided" do
      before do
        allow(DateTime).to receive(:now).and_return(date_today)
        actor.create_metadata(upload_set_id, nil)
      end
      it "assigns a default one" do
        expect(subject.generic_works.first.title).to contain_exactly("Default title")
      end
    end
  end
end
