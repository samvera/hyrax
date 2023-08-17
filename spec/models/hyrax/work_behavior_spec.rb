# frozen_string_literal: true
RSpec.describe Hyrax::WorkBehavior do
  before do
    class EssentialWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
    end
  end
  after do
    Object.send(:remove_const, :EssentialWork)
  end

  subject { EssentialWork.new }

  it 'mixes together some junk' do
    expect(subject.class.ancestors).to include(::Hyrax::HumanReadableType,
                                               Hyrax::Noid,
                                               Hyrax::Serializers,
                                               Hydra::WithDepositor,
                                               Hydra::AccessControls::Embargoable,
                                               Hyrax::Suppressible)
  end

  describe '#to_s' do
    it 'uses the provided titles' do
      subject.title = %w[Hello World]
      expect(subject.to_s).to include 'Hello'
      expect(subject.to_s).to include 'World'
    end
  end

  describe 'human_readable_type' do
    it 'has a default' do
      expect(subject.human_readable_type).to eq 'Essential Work'
    end
  end

  it 'inherits (and extends) to_solr behaviors from superclass' do
    expect(subject.to_solr.keys).to include(:id)
    expect(subject.to_solr.keys).to include('has_model_ssim')
  end

  describe 'indexer' do
    let(:klass) { Class.new }

    it 'is settable' do
      EssentialWork.indexer = klass
      expect(EssentialWork.indexer).to eq klass
    end
  end
end
