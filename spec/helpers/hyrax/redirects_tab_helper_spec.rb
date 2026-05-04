# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsTabHelper, type: :helper do
  let(:helper_class) do
    Class.new do
      include Hyrax::RedirectsTabHelper
    end
  end
  subject(:helper) { helper_class.new }

  let(:resource_with_redirects) { Struct.new(:redirects).new([]) }
  let(:resource_without_redirects) { Object.new }

  describe '#redirects_tab?' do
    before do
      allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
      # The form-class gate is exercised by its own context below; stub it true
      # for the other contexts so they isolate the redirects_active? and
      # respond_to?(:redirects) checks.
      allow(helper).to receive(:redirects_supported_form?).and_return(true)
    end

    context 'when the redirects feature is inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

      it 'returns false' do
        expect(helper.redirects_tab?(resource_with_redirects)).to be(false)
      end
    end

    context 'when the form is not a ResourceForm descendant' do
      before { allow(helper).to receive(:redirects_supported_form?).and_return(false) }

      it 'returns false even when the resource carries redirects' do
        expect(helper.redirects_tab?(resource_with_redirects)).to be(false)
      end
    end

    context 'when the resource carries the redirects attribute' do
      it 'returns true' do
        expect(helper.redirects_tab?(resource_with_redirects)).to be(true)
      end
    end

    context 'when the resource does not carry the redirects attribute' do
      it 'returns false' do
        expect(helper.redirects_tab?(resource_without_redirects)).to be(false)
      end
    end

    context 'when given a form-like wrapper that exposes #model' do
      let(:form) do
        Struct.new(:model).new(resource_with_redirects)
      end

      it 'unwraps the form and inspects the underlying model' do
        expect(helper.redirects_tab?(form)).to be(true)
      end

      context 'when the wrapped model lacks the redirects attribute' do
        let(:form) { Struct.new(:model).new(resource_without_redirects) }

        it 'returns false' do
          expect(helper.redirects_tab?(form)).to be(false)
        end
      end
    end
  end

  describe '#redirects_supported_form?' do
    it 'returns true for a Hyrax::Forms::ResourceForm instance' do
      form = Hyrax::Forms::ResourceForm.new(Hyrax::Resource.new)
      expect(helper.redirects_supported_form?(form)).to be(true)
    end

    it 'returns false for an arbitrary object' do
      expect(helper.redirects_supported_form?(Object.new)).to be(false)
    end
  end
end
