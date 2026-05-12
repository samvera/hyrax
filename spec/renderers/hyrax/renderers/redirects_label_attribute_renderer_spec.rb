# frozen_string_literal: true

RSpec.describe Hyrax::Renderers::RedirectsLabelAttributeRenderer do
  let(:options) { { base_url: 'https://example.edu' } }

  describe '#render_dl_row' do
    context 'with no values' do
      subject(:rendered) { described_class.new(:redirects, [], options).render_dl_row }

      it 'renders nothing' do
        expect(rendered).to eq('')
      end
    end

    context 'with a single path' do
      subject(:rendered) { described_class.new(:redirects, ['/handle/12345/678'], options).render_dl_row }

      it 'renders a link whose text is the full absolute URL' do
        expect(rendered).to include('https://example.edu/handle/12345/678')
      end

      it 'uses the path alone for the href' do
        expect(rendered).to include('href="/handle/12345/678"')
      end
    end

    context 'with multiple paths' do
      let(:paths) { ['/handle/12345/678', '/old/path/here'] }
      subject(:rendered) { described_class.new(:redirects, paths, options).render_dl_row }

      it 'renders one link per path' do
        expect(rendered).to include('https://example.edu/handle/12345/678')
        expect(rendered).to include('https://example.edu/old/path/here')
      end
    end

    context 'with a base_url that has a trailing slash' do
      let(:options) { { base_url: 'https://example.edu/' } }
      subject(:rendered) { described_class.new(:redirects, ['/handle/12345/678'], options).render_dl_row }

      it 'normalizes to a single slash between host and path' do
        expect(rendered).to include('https://example.edu/handle/12345/678')
        expect(rendered).not_to include('https://example.edu//handle')
      end
    end

    context 'with no base_url option' do
      subject(:rendered) { described_class.new(:redirects, ['/handle/12345/678'], {}).render_dl_row }

      it 'falls back to the path alone as the link text' do
        expect(rendered).to include('>/handle/12345/678</a>')
      end
    end

    context 'with a path containing special characters' do
      let(:path) { '/handle/12345/678 with spaces' }
      subject(:rendered) { described_class.new(:redirects, [path], options).render_dl_row }

      it 'HTML-escapes the path in the link text' do
        expect(rendered).to include('https://example.edu/handle/12345/678 with spaces')
      end
    end

    context 'with a blank value in the array (defensive)' do
      subject(:rendered) { described_class.new(:redirects, ['/handle/123', ''], options).render_dl_row }

      it 'does not render an empty link' do
        expect(rendered).not_to include('href=""')
      end
    end
  end
end
