# frozen_string_literal: true
RSpec.describe Hyrax::Renderers::DateAttributeRenderer do
  subject { Nokogiri::HTML(renderer.render) }

  let(:expected) { Nokogiri::HTML(tr_content) }

  describe "#attribute_to_html" do
    context 'with embargo release date' do
      let(:field) { :embargo_release_date }
      let(:renderer) { described_class.new(field, ['2013-03-14T00:00:00Z']) }
      let(:tr_content) do
        %(
      <tr><th>Embargo release date</th>
      <td><ul class="tabular">
      <li class="attribute attribute-embargo_release_date">03/14/2013</li>
      </ul></td></tr>
      )
      end

      it { expect(renderer).not_to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end

    context 'with lease expiration date' do
      let(:field) { :lease_expiration_date }
      let(:renderer) { described_class.new(field, ['2013-03-14T00:00:00Z']) }
      let(:tr_content) do
        %(
      <tr><th>Lease expiration date</th>
      <td><ul class="tabular">
      <li class="attribute attribute-lease_expiration_date">03/14/2013</li>
      </ul></td></tr>
      )
      end

      it { expect(renderer).not_to be_microdata(field) }
      it { expect(subject).to be_equivalent_to(expected) }
    end
  end
end
