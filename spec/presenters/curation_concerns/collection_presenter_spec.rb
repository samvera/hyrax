require 'spec_helper'

describe CurationConcerns::CollectionPresenter do
  describe '.terms' do
    subject { described_class.terms }
    it do
      is_expected.to eq [:title, :total_items, :size, :resource_type, :description, :creator,
                         :contributor, :tag, :rights, :publisher, :date_created, :subject,
                         :language, :identifier, :based_near, :related_url]
    end
  end

  let(:collection) { Collection.new(description: 'a nice collection', title: 'A clever title') }
  let(:presenter) { described_class.new(collection) }

  describe '#terms_with_values' do
    subject { presenter.terms_with_values }

    it { is_expected.to eq [:title, :total_items, :size, :description] }
  end

  describe '#title' do
    subject { presenter.title }
    it { is_expected.to eq 'A clever title' }
  end

  describe '#size' do
    subject { presenter.size }
    it { is_expected.to eq '0 Bytes' }
  end

  describe '#total_items' do
    subject { presenter.total_items }
    it { is_expected.to eq 0 }
  end
end
