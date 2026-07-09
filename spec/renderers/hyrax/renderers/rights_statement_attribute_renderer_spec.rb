# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::RightsStatementAttributeRenderer do
  let(:field) { :rights_statement }
  let(:renderer) { described_class.new(field, ['http://rightsstatements.org/vocab/InC/1.0/']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      "<tr><th>Rights statement</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute attribute-rights_statement\"><a href=\"http://rightsstatements.org/vocab/InC/1.0/\" target=\"_blank\" rel=\"noopener noreferrer\">In Copyright</a></li>" \
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
