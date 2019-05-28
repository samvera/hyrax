# frozen_string_literal: true
require 'wings_helper'
require 'wings/services/active_fedora_reloader_service'

RSpec.describe Wings::ActiveFedoraReloaderService do
  let(:af_object) { create(:generic_work) }
  let(:child_work) { create(:generic_work) }

  before do
    work_copy = ActiveFedora::Base.find(af_object.id)
    work_copy.description = ["3 Crumpets and a Teacake"]
    work_copy.ordered_members << child_work
    work_copy.save!
  end

  describe '#reload' do
    it 'updates the associations for the object' do
      expect(described_class.reload(af_object).members).to eq [child_work]
    end
    it 'updates the metadata' do
      expect(described_class.reload(af_object).description).to eq ["3 Crumpets and a Teacake"]
    end
  end
end
