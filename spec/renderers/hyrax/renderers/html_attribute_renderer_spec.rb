# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::HtmlAttributeRenderer do
  let(:field) { :context_narrative }
  let(:renderer) { described_class.new(field, [value]) }

  subject(:html) { renderer.render }

  describe '#render' do
    context 'with allowed markup' do
      let(:value) do
        '<p>Hello <strong>world</strong> ' \
          '<a href="https://example.com" title="more">link</a></p>'
      end

      it 'preserves allowed tags' do
        expect(html).to include('<strong>world</strong>')
      end

      it 'preserves allowed attributes' do
        expect(html).to include('href="https://example.com"').and include('title="more"')
      end

      it 'returns an html-safe string' do
        expect(html).to be_html_safe
      end
    end

    context 'with disallowed markup' do
      let(:value) do
        '<a href="https://example.com" onclick="steal()">ok</a>' \
          '<script>alert("xss")</script>' \
          '<img src="x" onerror="alert(1)">'
      end

      it 'keeps the safe parts of allowed tags' do
        expect(html).to include('href="https://example.com"')
      end

      it 'strips event-handler attributes' do
        expect(html).not_to include('onclick')
      end

      it 'strips <script> tags' do
        expect(html).not_to include('<script')
      end

      it 'strips disallowed tags' do
        expect(html).not_to include('<img')
      end
    end

    context 'with a target="_blank" link' do
      let(:value) { '<p><a href="https://example.com" target="_blank">x</a></p>' }

      it 'adds rel="noopener noreferrer" to prevent reverse tabnabbing' do
        expect(html).to include('rel="noopener noreferrer"')
      end
    end

    context 'with a target="_blank" link that already declares a rel' do
      let(:value) { '<p><a href="https://example.com" target="_blank" rel="nofollow">x</a></p>' }

      it 'preserves the existing rel and de-duplicates the safety tokens' do
        expect(html).to include('nofollow').and include('noopener').and include('noreferrer')
        expect(html.scan('noopener').size).to eq(1)
      end
    end

    context 'with a blank value' do
      let(:value) { nil }

      it 'renders nothing' do
        expect(renderer.render).to eq('')
      end
    end
  end

  # The renderer must own its value rendering so that a markdown/escaping
  # decorator prepended onto the base AttributeRenderer by a downstream app
  # (e.g. Hyku's `treat_some_user_inputs_as_markdown` flag wraps values in
  # `markdown()`) cannot intercept and re-process sanitized HTML.
  describe 'rendering ownership (flag independence)' do
    it 'overrides attribute_value_to_html on the class itself' do
      expect(described_class.instance_method(:attribute_value_to_html).owner).to eq(described_class)
    end
  end
end
