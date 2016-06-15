require 'spec_helper'

RSpec.describe Hydra::ContentNegotiation::ReplacingGraphFinder do
  let(:graph) { double }
  let(:finder) { double(graph: graph,
                        uri: 'http://127.0.0.1:8986/rest/test/28/01/ph/00/2801ph009',
                        id: '2801ph009') }
  let(:replacer) { double }
  subject { described_class.new finder, replacer }

  describe "graph" do
    it "has the correct base url" do
      expect(Hydra::ContentNegotiation::FedoraUriReplacer).to receive(:new)
      .with(ending_with("/rest/test"), graph, replacer)
       .and_return(double(run: nil))

      subject.graph
    end
  end
end
