require 'spec_helper'

describe 'hyrax/base/unauthorized.html.erb' do
  context "when it responds to curation_concern" do
    let(:concern) { double(human_readable_type: 'Book', id: '777') }
    before do
      allow(view).to receive(:curation_concern).and_return(concern)
      render
    end
    it "shows a message to the user" do
      expect(rendered).to have_content "Unauthorized The book you have tried to access is private ID: 777"
    end

    context "and the concern is nil" do
      let(:concern) { nil }
      it "shows a message to the user" do
        expect(rendered).to have_content "Unauthorized The page you have tried to access is private"
      end
    end
  end

  context "when it doesn't respond to curation_concern" do
    before do
      render
    end
    it "shows a message to the user" do
      expect(rendered).to have_content "Unauthorized The page you have tried to access is private"
    end
  end
end
