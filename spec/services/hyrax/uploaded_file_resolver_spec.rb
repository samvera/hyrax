# frozen_string_literal: true
RSpec.describe Hyrax::UploadedFileResolver do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:upload) { FactoryBot.create(:uploaded_file, user: user) }
  let(:foreign_upload) { FactoryBot.create(:uploaded_file, user: other_user) }

  describe '.call' do
    it "resolves ids to the user's uploaded files" do
      expect(described_class.call([upload.id.to_s], user: user)).to eq [upload]
    end

    it 'preserves the order of the given ids' do
      second = FactoryBot.create(:uploaded_file, user: user)

      expect(described_class.call([second.id, upload.id], user: user))
        .to eq [second, upload]
    end

    it 'returns [] for nil' do
      expect(described_class.call(nil, user: user)).to eq []
    end

    it 'returns [] for blank ids' do
      expect(described_class.call(['', nil], user: user)).to eq []
    end

    it 'raises OwnershipError for files owned by another user' do
      expect { described_class.call([foreign_upload.id], user: user) }
        .to raise_error described_class::OwnershipError
    end

    it 'raises OwnershipError when any file in the batch is foreign' do
      expect { described_class.call([upload.id, foreign_upload.id], user: user) }
        .to raise_error described_class::OwnershipError
    end

    it 'logs which files failed the ownership check' do
      allow(Hyrax.logger).to receive(:error)

      expect { described_class.call([foreign_upload.id], user: user) }
        .to raise_error described_class::OwnershipError
      expect(Hyrax.logger).to have_received(:error)
        .with(a_string_including("uploaded_file #{foreign_upload.id}"))
    end

    it 'raises RecordNotFound for ids that do not exist' do
      expect { described_class.call(['999999999'], user: user) }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end
