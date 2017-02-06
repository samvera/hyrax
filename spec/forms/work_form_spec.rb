require 'spec_helper'

describe CurationConcerns::Forms::WorkForm do
  before do
    class PirateShip < ActiveFedora::Base
      include CurationConcerns::RequiredMetadata
      include CurationConcerns::BasicMetadata
      include CurationConcerns::HasRepresentative
    end

    class PirateShipForm < described_class
      self.model_class = ::PirateShip
    end
  end

  after do
    Object.send(:remove_const, :PirateShipForm)
    Object.send(:remove_const, :PirateShip)
  end

  let(:curation_concern) { create(:work) }
  let(:ability) { nil }
  let(:form) { PirateShipForm.new(curation_concern, ability) }

  describe "#version" do
    before do
      allow(curation_concern).to receive(:etag).and_return('123456')
    end
    subject { form.version }
    it { is_expected.to eq '123456' }
  end

  describe "#select_files" do
    let(:curation_concern) { create(:work_with_one_file) }
    let(:title) { curation_concern.file_sets.first.title.first }
    let(:file_id) { curation_concern.file_sets.first.id }

    subject { form.select_files }
    it { is_expected.to eq(title => file_id) }
  end

  describe "#[]" do
    it 'has one element' do
      expect(form['description']).to eq ['']
    end
  end

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(
      title: ['foo'],
      description: [''],
      visibility: 'open',
      admin_set_id: '123',
      representative_id: '456',
      thumbnail_id: '789',
      keyword: ['derp'],
      source: ['related'],
      rights: ['http://creativecommons.org/licenses/by/3.0/us/'])
    }
    subject { PirateShipForm.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['rights']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['keyword']).to eq ['derp']
      expect(subject['source']).to eq ['related']
    end

    it 'excludes non-permitted params' do
      expect(subject).not_to have_key 'admin_set_id'
    end
  end

  describe "initialized fields" do
    context "for :description" do
      subject { form[:description] }
      it { is_expected.to eq [''] }
    end

    context "for :embargo_release_date" do
      subject { form[:embargo_release_date] }
      it { is_expected.to be nil }
    end
  end

  describe '#visibility' do
    subject { form.visibility }
    it { is_expected.to eq 'restricted' }
  end

  describe '#human_readable_type' do
    subject { form.human_readable_type }
    it { is_expected.to eq 'Generic Work' }
  end

  describe "#open_access?" do
    subject { form.open_access? }
    it { is_expected.to be false }
  end

  describe "#authenticated_only_access?" do
    subject { form.authenticated_only_access? }
    it { is_expected.to be false }
  end

  describe "#open_access_with_embargo_release_date?" do
    subject { form.open_access_with_embargo_release_date? }
    it { is_expected.to be false }
  end

  describe "#private_access?" do
    subject { form.private_access? }
    it { is_expected.to be true }
  end

  describe "#member_ids" do
    subject { form.member_ids }
    it { is_expected.to eq curation_concern.member_ids }
  end

  describe "#embargo_release_date" do
    let(:curation_concern) { create(:work, embargo_release_date: 5.days.from_now) }
    subject { form.embargo_release_date }
    it { is_expected.to eq curation_concern.embargo_release_date }
  end

  describe "#lease_expiration_date" do
    let(:curation_concern) { create(:work, lease_expiration_date: 2.days.from_now) }
    subject { form.lease_expiration_date }
    it { is_expected.to eq curation_concern.lease_expiration_date }
  end

  describe ".required_fields" do
    subject { described_class.required_fields }
    it { is_expected.to eq [:title] }
  end
end
