require 'spec_helper'

describe CurationConcerns::Forms::CollectionEditForm do
  let(:collection) { Collection.new }
  let(:form) { described_class.new(collection) }

  describe '#terms' do
    subject { form.terms }
    it do
      is_expected.to eq [:resource_type, :title, :creator, :contributor, :description,
                         :tag, :rights, :publisher, :date_created, :subject, :language,
                         :identifier, :based_near, :related_url]
    end
  end

  describe 'unique?' do
    context 'with :title' do
      subject { described_class.unique?(:title) }
      it { is_expected.to be true }
    end
  end
end
