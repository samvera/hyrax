require 'spec_helper'

describe CurationConcerns::UploadSetForm do
  let(:form) { described_class.new(upload_set, ability) }
  let(:user) { build(:user) }
  let(:ability) { Ability.new(user) }
  let(:upload_set) { UploadSet.create }
  let!(:work1) { create(:work, upload_set: upload_set) }
  let!(:work2) { create(:work, upload_set: upload_set) }

  describe "#to_param" do
    subject { form.to_param }
    it { is_expected.to eq upload_set.id }
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
                            :visibility] }
  end

  describe "works" do
    let!(:work1) { create(:work_with_one_file, upload_set: upload_set, title: ['B title']) }
    let!(:work2) { create(:work_with_one_file, upload_set: upload_set, title: ['A title']) }
    subject { form.works }
    it { is_expected.to eq [work2, work1] }
  end

  describe "creator" do
    let(:user) { build(:user, email: 'bob@example.com') }
    subject { form.creator }
    it { is_expected.to eq ['bob@example.com'] }
  end
end
