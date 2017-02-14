require 'spec_helper'
describe Hyrax::Actors::ActorStack do
  let(:user_or_ability) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    described_class.new(curation_concern,
                        user_or_ability,
                        [])
  end

  context "when an ability is passed as the second argument" do
    let(:user_or_ability) { Ability.new(create(:user)) }
    it "assigns user to the ability's user" do
      expect(subject.user).to eq user_or_ability.current_user
    end
  end

  ## Remove these specs when user support is removed.
  context "when a user is passed as the second argument" do
    let(:user_or_ability) { create(:user) }
    before do
      allow(Deprecation).to receive(:warn)
    end
    it "assigns user the user" do
      expect(subject.user).to eq user_or_ability
    end
    it "builds an ability" do
      expect(subject.ability.current_user).to eq user_or_ability
    end
    it "throws a deprecation warning" do
      expect(Deprecation).to have_received(:warn).with(subject, "Passing a user as an argument to Hyrax::Actors::ActorStack is deprecated, pass an Ability instead")
    end
  end
end
