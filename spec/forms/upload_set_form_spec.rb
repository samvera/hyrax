require 'spec_helper'

describe Sufia::UploadSetForm do
  let(:form) { described_class.new(model, ability) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }
  let(:model) { UploadSet.new }

  describe "#creator" do
    subject { form.creator }
    it { is_expected.to eq ['Jill Z. User'] }
  end

  let!(:work1) { create(:work, upload_set: model) }
  let!(:work2) { create(:work, upload_set: model) }

  describe "#to_param" do
    subject { form.to_param }
    it { is_expected.to eq model.id }
  end

  describe "#terms" do
    subject { form.terms }
    it { is_expected.to eq [:title,
                            :creator,
                            :contributor,
                            :description,
                            :tag,
                            :rights,
                            :publisher,
                            :date_created,
                            :subject,
                            :language,
                            :identifier,
                            :based_near,
                            :related_url,
                            :representative_id,
                            :thumbnail_id,
                            :files,
                            :visibility_during_embargo,
                            :embargo_release_date,
                            :visibility_after_embargo,
                            :visibility_during_lease,
                            :lease_expiration_date,
                            :visibility_after_lease,
                            :visibility,
                            :ordered_member_ids,
                            :collection_ids,
                            :resource_type] }
  end

  describe "works" do
    let!(:work1) { create(:work_with_one_file, upload_set: model, title: ['B title']) }
    let!(:work2) { create(:work_with_one_file, upload_set: model, title: ['A title']) }
    subject { form.works }
    it { is_expected.to eq [work2, work1] }
  end
end
