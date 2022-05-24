# frozen_string_literal: true
RSpec.describe Hyrax::ValkyriePersistDerivatives do
  before do
    allow(Hyrax.config)
      .to receive(:derivatives_path)
      .and_return('/app/samvera/hyrax-webapp/derivatives/')
  end

  describe '.call' do
    let(:directives) do
      { url: "file:///app/samvera/hyrax-webapp/derivatives/#{id}/3-thumbnail.jpeg" }
    end
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:id) { file_set.id }
    let(:stream) { StringIO.new('moomin') }

    it 'uploads the processed file' do
      expect { described_class.call(stream, directives) }
        .to change { Hyrax.custom_queries.find_files(file_set: file_set) }
        .from(be_empty)
    end
  end
end
