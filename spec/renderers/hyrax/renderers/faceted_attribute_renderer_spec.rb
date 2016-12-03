require 'spec_helper'

describe Hyrax::Renderers::FacetedAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['Bob', 'Jessica']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }

    let(:tr_content) do
      %(
      <tr><th>Name</th>
      <td><ul class='tabular'>
      <li class="attribute name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Bob">Bob</a></li>
      <li class="attribute name"><a href="/catalog?f%5Bname_sim%5D%5B%5D=Jessica">Jessica</a></li>
      </ul></td></tr>
    )
    end
    it { expect(renderer).not_to be_microdata(field) }
    it { expect(subject).to be_equivalent_to(expected) }
  end
end
