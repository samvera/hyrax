# frozen_string_literal: true
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe FileSet do
  subject(:file_set) { described_class.new }

  it_behaves_like 'a Hyrax::FileSet'

  describe '#human_readable_type' do
    it 'has a human readable type' do
      expect(file_set.human_readable_type).to eq 'File Set'
    end
  end
end
