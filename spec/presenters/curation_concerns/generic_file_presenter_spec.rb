require 'spec_helper'

describe CurationConcerns::GenericFilePresenter do
  describe '.terms' do
    it 'returns a list' do
      expect(described_class.terms).to eq([:resource_type, :title,
                                           :creator, :contributor, :description, :tag, :rights, :publisher,
                                           :date_created, :subject, :language, :identifier, :based_near,
                                           :related_url])
    end
  end

  let(:presenter) { described_class.new(file) }
end
