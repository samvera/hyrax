
describe "sufia/homepage/_announcement.html.erb" do
  let(:groups) { [] }
  let(:ability) { instance_double("Ability") }
  let(:announcement) { ContentBlock.new(name: ContentBlock::ANNOUNCEMENT, value: announcement_value) }

  subject { rendered }

  before do
    assign(:announcement_text, announcement)
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:update, ContentBlock).and_return(can_update_content_block)
    render
  end

  context "when there is an announcement" do
    let(:announcement_value) { "I have an announcement!" }

    context "when the user can update content" do
      let(:can_update_content_block) { true }

      it { is_expected.to have_content announcement_value }
      it { is_expected.to have_button("Edit") }
    end

    context "when the user can't update content" do
      let(:can_update_content_block) { false }

      it { is_expected.to have_content announcement_value }
      it { is_expected.not_to have_button("Edit") }
    end
  end

  context "when there is no announcement" do
    let(:announcement_value) { "" }

    context "when the user can update content" do
      let(:can_update_content_block) { true }

      it { is_expected.to have_selector "#announcement" }
      it { is_expected.to have_button("Edit") }
    end

    context "when the user can't update content" do
      let(:can_update_content_block) { false }

      it { is_expected.not_to have_selector "#announcement" }
    end
  end
end
