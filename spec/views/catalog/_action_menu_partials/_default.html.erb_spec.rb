require 'spec_helper'

describe 'catalog/_action_menu_partials/_default.html.erb' do
  let(:document) { double }
  subject { rendered }

  context "when neither a editor or a collector" do
    before do
      allow(view).to receive(:can?).and_return(false)
      render 'catalog/_action_menu_partials/default.html.erb', document: document
    end
    it { is_expected.to eq '' }
  end
end
