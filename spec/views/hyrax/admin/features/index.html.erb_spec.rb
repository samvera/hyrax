# frozen_string_literal: true
RSpec.describe "hyrax/admin/features/index.html.erb", type: :view do
  let(:ability) { instance_double("Ability") }
  let(:feature_set) do
    Flipflop::FeaturesController::FeaturesPresenter.new(Flipflop::FeatureSet.current)
  end

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    assign(:feature_set, feature_set)
  end
  it "shows list of features" do
    render
    expect(rendered).to have_content('enabled')
  end
end
