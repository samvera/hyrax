require 'spec_helper'

describe Hyrax::PresenterFactory do
  describe "#build_presenters" do
    let(:presenter_class) { Hyrax::FileSetPresenter }

    before do
      allow(ActiveFedora::SolrService.instance.conn).to receive(:post)
        .with('select', data: { q: "{!terms f=id}12,13", rows: 1000, qt: 'standard' })
        .and_return('response' => { 'docs' => results })
    end

    subject { described_class.build_presenters(['12', '13'], presenter_class, nil) }

    context "when some ids are found in solr" do
      let(:results) { [{ "id" => "12" }, { "id" => "13" }] }
      it "has two results" do
        expect(subject.size).to eq 2
      end
    end

    context "when some ids are not found in solr" do
      let(:results) { [{ "id" => "13" }] }
      it "has one result" do
        expect(subject.size).to eq 1
      end
    end

    context "with more arguments" do
      let(:presenter_class) do
        Class.new(Hyrax::FileSetPresenter) do
          attr_reader :two, :three
          def initialize(_one, two, three)
            @two = two
            @three = three
          end
        end
      end
      let(:results) { [{ "id" => "12" }, { "id" => "13" }] }
      subject do
        described_class.build_presenters(['12', '13'],
                                         presenter_class,
                                         'more',
                                         'and more')
      end
      it 'passes all the arguments' do
        expect(subject.first.two).to eq 'more'
        expect(subject.first.three).to eq 'and more'
      end
    end
  end
end
