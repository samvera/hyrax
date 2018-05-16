RSpec.describe Hyrax::Renderers::FacetedAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }

    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      %(
      <tr><th>Name</th>
      <td><ul class='tabular'>
      <li class="attribute attribute-name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Bob&locale=en">Bob</a></li>
      <li class="attribute attribute-name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Jessica&locale=en">Jessica</a></li>
      </ul></td></tr>
    )
    end

    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end

  describe "href generated" do
    describe "escaping" do
      let(:renderer) { described_class.new(field, ['John & Bob']) }
      let(:rendered_link) { Nokogiri::HTML(renderer.render).at_css("a") }
      let(:rendered_link_query) { URI.parse(rendered_link['href']).query }

      it "escapes content properly" do
        expect(rendered_link_query).to eq "#{CGI.escape('f[name_sim][]')}=#{CGI.escape('John & Bob')}&locale=en"
      end
    end
  end
end
