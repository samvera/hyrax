# frozen_string_literal: true
RSpec.describe Hyrax::FileSetFixityCheckService,
               pending: Hyrax.config.disable_wings ? 'Valkyrie rewrite needed' : false do
  let(:f)                 { create(:file_set, :image) }
  let(:service_by_object) { described_class.new(f) }
  let(:service_by_id)     { described_class.new(f.id) }

  describe "async_jobs: false" do
    let(:service_by_object) { described_class.new(f, async_jobs: false) }
    let(:service_by_id)     { described_class.new(f.id, async_jobs: false) }

    describe '#fixity_check' do
      subject { service_by_object.fixity_check }

      context 'when a file has two versions' do
        before do
          Hyrax::VersioningService.create(f.original_file) # create a second version -- the factory creates the first version when it attaches +content+
        end
        specify 'returns two log results' do
          expect(subject.values.flatten.length).to eq(2)
        end

        context "with latest_version_only" do
          let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true) }

          specify "returns one log result" do
            expect(subject.values.length).to eq(1)
          end
        end
      end

      context "existing check and disabled max_days_between_fixity_checks" do
        let(:service_by_object) { described_class.new(f, async_jobs: false, max_days_between_fixity_checks: -1) }
        let(:service_by_id)     { described_class.new(f.id, async_jobs: false, max_days_between_fixity_checks: -1) }
        let!(:existing_record) do
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.versions.first.label, file_id: f.original_file.id)
        end

        it "re-checks" do
          existing_record
          expect(subject.length).to eq 1
          expect(subject.values.flatten.first.id).not_to eq(existing_record.id)
          expect(subject.values.flatten.first.created_at).to be > existing_record.created_at
        end
      end
    end

    describe '#fixity_check_file' do
      subject { service_by_object.send(:fixity_check_file, f.original_file) }

      specify 'returns a single result' do
        expect(subject.length).to eq(1)
      end
      describe 'non-versioned file with latest version only' do
        let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true) }

        before do
          allow(f.original_file).to receive(:has_versions?).and_return(false)
        end

        subject { service_by_object.send(:fixity_check_file, f.original_file) }

        specify 'returns a single result' do
          expect(subject.length).to eq(1)
        end
      end
    end

    describe '#fixity_check_file_version' do
      subject { service_by_object.send(:fixity_check_file_version, f.original_file.id, f.original_file.uri.to_s) }

      specify 'returns a single ChecksumAuditLog for the given file' do
        expect(subject).to be_kind_of ChecksumAuditLog
        expect(subject.file_set_id).to eq(f.id)
        expect(subject.checked_uri).to eq(f.original_file.uri)
      end
    end
  end
end
