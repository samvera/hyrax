require 'spec_helper'
describe Hyrax::Actors::ActorStack do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }

  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    described_class.new(curation_concern,
                        ability,
                        [])
  end

  it "delegates user to the ability" do
    expect(subject.user).to eq user
  end

  it "has ability" do
    expect(subject.ability).to eq ability
  end
end
