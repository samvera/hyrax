RSpec.describe Hyrax::Renderers::RightsStatementAttributeRenderer do
  let(:field) { :rights_statement }
  let(:renderer) { described_class.new(field, ['http://rightsstatements.org/vocab/InC/1.0/']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      "<tr><th>Rights statement</th>\n" \
       "<td><ul class='tabular'>" \
       "<li class=\"attribute rights_statement\"><a href=\"http://rightsstatements.org/vocab/InC/1.0/\" target=\"_blank\">In Copyright</a></li>" \
       "</ul></td></tr>"
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
