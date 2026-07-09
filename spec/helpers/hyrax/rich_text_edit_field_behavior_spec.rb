# frozen_string_literal: true
RSpec.describe Hyrax::RichTextEditFieldBehavior do
  # Minimal stand-in for hydra-editor's RecordsHelperBehavior, providing the
  # fallback #render_edit_field_partial that the module reaches via `super`.
  let(:base_module) do
    Module.new do
      def render_edit_field_partial(_field_name, _locals)
        :fallback
      end
    end
  end

  let(:helper_class) do
    base = base_module
    Class.new do
      include base
      prepend Hyrax::RichTextEditFieldBehavior

      # Stub Rails' #render so we can assert what would be rendered.
      def render(partial, locals)
        { partial: partial, locals: locals }
      end
    end
  end

  let(:helper) { helper_class.new }
  let(:f) { double('form_builder', object: form) }

  context 'when the field is declared as rich_text' do
    let(:form) { double('form') }

    before { allow(form).to receive(:input_type).with(:narrative).and_return(:rich_text) }

    it 'renders the shared rich_text edit-field partial' do
      result = helper.render_edit_field_partial(:narrative, f: f)

      expect(result[:partial]).to eq('records/edit_fields/rich_text')
      expect(result[:locals]).to include(key: :narrative, f: f)
    end
  end

  context 'when the field declares no rich_text input type' do
    let(:form) { double('form') }

    before { allow(form).to receive(:input_type).with(:title).and_return(nil) }

    it 'falls back to the default partial lookup' do
      expect(helper.render_edit_field_partial(:title, f: f)).to eq(:fallback)
    end
  end

  context 'when the form does not support input_type (e.g. legacy forms)' do
    let(:form) { Object.new }

    it 'falls back to the default partial lookup' do
      expect(helper.render_edit_field_partial(:title, f: f)).to eq(:fallback)
    end
  end
end
