# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::DeactivateObject do
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, state: Hyrax::ResourceStatus::ACTIVE) }
  let(:user) { FactoryBot.create(:user) }

  subject(:workflow_method) { described_class }

  it_behaves_like "a Hyrax workflow method"

  describe ".call" do
    it "makes it inactive" do
      expect { described_class.call(target: work, comment: "A pleasant read", user: user) }
        .to change { work.state }
        .from(Hyrax::ResourceStatus::ACTIVE)
        .to(Hyrax::ResourceStatus::INACTIVE)
    end
  end
end
