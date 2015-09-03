require 'spec_helper'

describe CurationConcerns::FormPresenter do
  let(:curation_concern) { create(:work_with_one_file) }
  let(:title) { curation_concern.generic_files.first.title.first }
  let(:file_id) { curation_concern.generic_files.first.id }
  let(:ability) { nil }
  let(:presenter) { described_class.new(curation_concern, ability) }

  describe "#files_hash" do
    subject { presenter.files_hash }
    it { is_expected.to eq(title => file_id) }
  end
end
