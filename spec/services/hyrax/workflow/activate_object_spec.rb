# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::ActivateObject do
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, state: Hyrax::ResourceStatus::INACTIVE) }
  let(:user) { FactoryBot.create(:user) }

  subject(:workflow_method) { described_class }

  it_behaves_like "a Hyrax workflow method"

  describe ".call" do
    it "makes it active" do
      expect { workflow_method.call(target: work, comment: "A pleasant read", user: user) }
        .to change { work.state }
        .from(Hyrax::ResourceStatus::INACTIVE)
        .to(Hyrax::ResourceStatus::ACTIVE)
    end
  end
end
