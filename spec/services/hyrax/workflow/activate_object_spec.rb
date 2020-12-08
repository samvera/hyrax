# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::ActivateObject do
  let(:work) { create(:generic_work) }
  let(:user) { create(:user) }

  let(:workflow_method) { described_class }

  it_behaves_like "a Hyrax workflow method"

  describe ".call" do
    it "makes it active" do
      expect { described_class.call(target: work, comment: "A pleasant read", user: user) }
        .to change { work.state }
        .from(nil)
        .to(::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#active'))
    end
  end
end
