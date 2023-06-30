# frozen_string_literal: true
RSpec.describe Hyrax::ContentBlockHelper, type: :helper do
  let(:content_block) { create(:content_block, value: "<p>foo bar</p>") }

  describe '#displayable_content_block' do
    let(:options) { {} }

    subject { helper.displayable_content_block(content_block, **options) }

    it 'is defined' do
      expect(helper).to respond_to(:displayable_content_block)
    end

    context 'when a block is nil' do
      let(:content_block) { nil }

      it { is_expected.to be_nil }
    end

    context 'when a block has a nil value' do
      let(:content_block) { double(value: nil) }

      it { is_expected.to be_nil }
    end

    context 'when a block has an empty string value' do
      let(:content_block) { double(value: '') }

      it { is_expected.to be_nil }
    end

    context 'when a block has a non-empty string value' do
      let(:content_block) { double(value: value) }
      let(:value) { '<p>foobarbaz</p>' }

      it { is_expected.to eq "<div>#{value}</div>" }

      context 'with options' do
        let(:options) { { id: 'my_id', class: 'huge' } }

        it { is_expected.to eq "<div id=\"my_id\" class=\"huge\">#{value}</div>" }
      end
    end
  end
end
