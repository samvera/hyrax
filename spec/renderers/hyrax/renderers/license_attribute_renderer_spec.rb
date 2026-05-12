# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::LicenseAttributeRenderer do
  let(:field) { :license }
  let(:renderer) { described_class.new(field, ['http://creativecommons.org/licenses/by/3.0/us/', 'http://creativecommons.org/licenses/by-nd/3.0/us/']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      "<tr><th>License</th>\n" \
       "<td><ul class='tabular'>\n" \
       "<li class=\"attribute attribute-license\">" \
         "<a href=\"http://creativecommons.org/licenses/by/3.0/us/\" target=\"_blank\" rel=\"noopener noreferrer\">" \
         "Attribution 3.0 United States</a></li>\n" \
       "<li class=\"attribute attribute-license\">" \
         "<a href=\"http://creativecommons.org/licenses/by-nd/3.0/us/\" target=\"_blank\" rel=\"noopener noreferrer\">" \
         "Attribution-NoDerivs 3.0 United States</a></li>\n" \
       "</ul></td></tr>"
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }

    context 'with off-authority term' do
      let(:renderer) { described_class.new(field, [value]) }
      let(:value)    { 'moomin' }

      it 'renders a value' do
        expect(subject.to_s).to include value
      end

      it 'does not render free-text values as links' do
        expect(subject.css('a').to_a).to be_empty
      end
    end

    context 'with an unsafe scheme' do
      let(:renderer) { described_class.new(field, ['javascript:alert(1)']) }

      it 'renders the value as plain text rather than a link' do
        expect(subject.css('a').to_a).to be_empty
      end

      it 'escapes the value' do
        expect(subject.to_s).not_to include 'href="javascript'
      end
    end
  end
end
