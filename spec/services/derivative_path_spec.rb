require 'spec_helper'

describe CurationConcerns::DerivativePath do
  before do
    allow(CurationConcerns.config).to receive(:derivatives_path).and_return('tmp')
  end

  describe '.derivative_path_for_reference' do
    subject { described_class.derivative_path_for_reference(object, destination_name) }

    let(:object) { double(id: '123') }
    let(:destination_name) { 'thumbnail' }

    it { is_expected.to eq 'tmp/123/thumbnail.jpeg' }
  end
end
