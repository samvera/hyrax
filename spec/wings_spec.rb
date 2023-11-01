# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'wings'

RSpec.describe Wings, :active_fedora do
  describe 'WorkSearchBuilder' do
    it "does not pollute the class variables after separate calls" do
      generic_work_search_builder = described_class::WorkSearchBuilder(Hyrax::Test::SimpleWork)
      monograph_search_builder = described_class::WorkSearchBuilder(Monograph)
      expect(monograph_search_builder).not_to eq(generic_work_search_builder)
      expect(monograph_search_builder.legacy_work_type).not_to eq(generic_work_search_builder.legacy_work_type)
    end
  end

  it 'adds mixin to AF::Base' do
    expect(GenericWork.new).to respond_to :valkyrie_resource
  end
end
