# frozen_string_literal: true
RSpec.describe "hyrax/homepage/_announcement.html.erb", type: :view do
  let(:groups) { [] }
  let(:ability) { instance_double("Ability") }
  let(:announcement) { ContentBlock.new(name: ContentBlock::NAME_REGISTRY[:announcement], value: announcement_value) }

  subject { rendered }

  before do
    view.extend Hyrax::ContentBlockHelper
    assign(:announcement_text, announcement)
    allow(controller).to receive(:current_ability).and_return(ability)
    render
  end

  context "when there is an announcement" do
    let(:announcement_value) { "I have an announcement!" }

    it { is_expected.to have_content announcement_value }
    it { is_expected.not_to have_button("Edit") }
  end

  context "when there is no announcement" do
    let(:announcement_value) { "" }

    it { is_expected.not_to have_selector "#announcement" }
  end
end
