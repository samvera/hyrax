# frozen_string_literal: true

include ActionDispatch::TestProcess

RSpec.describe Hyrax::FileSetFixityCheckService do
  let(:f)                 { create_for_repository(:file_set, content: fixture_file_upload('world.png', 'image/png')) }
  let(:service_by_object) { described_class.new(f) }
  let(:service_by_id)     { described_class.new(f.id) }

  describe "async_jobs: false" do
    let(:service_by_object) { described_class.new(f, async_jobs: false) }
    let(:service_by_id)     { described_class.new(f.id, async_jobs: false) }

    describe '#fixity_check' do
      subject { service_by_object.fixity_check }

      context 'when a file has two versions' do
        before do
          # Hyrax::VersioningService.create(f.original_file) # create a second version -- the factory creates the first version when it attaches +content+
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
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.file_identifiers.first, file_id: f.original_file.id)
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
      subject { service_by_object.send(:fixity_check_file, f.original_file.file_identifiers.first) }

      specify 'returns a single result' do
        expect(subject.length).to eq(1)
      end
    end

    describe '#fixity_check_file_version' do
      subject { service_by_object.send(:fixity_check_file_version, f.original_file.id, f.original_file.file_identifiers.first) }

      specify 'returns a single ChecksumAuditLog for the given file' do
        expect(subject).to be_kind_of ChecksumAuditLog
        expect(subject.file_set_id).to eq(f.id)
        expect(subject.checked_uri).to eq(f.original_file.uri)
      end
    end
  end

  describe '#logged_fixity_status' do
    around do |example|
      # Deprecation.silence is supposed to be a thing, but I can't get it to work
      original = Deprecation.default_deprecation_behavior
      Deprecation.default_deprecation_behavior = :silence
      example.run
      Deprecation.default_deprecation_behavior = original
    end

    context "with an object" do
      subject { service_by_object.logged_fixity_status }

      it "doesn't trigger fixity checks" do
        expect(service_by_object).not_to receive(:fixity_check_file)
        expect(subject).to eq "Fixity checks have not yet been run on this object"
      end

      context "when no fixity check is passing" do
        before do
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.file_identifiers.first, file_id: 'original_file')
        end

        it "reports the fixity check result" do
          expect(subject).to include "passed"
        end
      end

      context "when most recent fixity check is passing" do
        before do
          ChecksumAuditLog.create!(passed: false, file_set_id: f.id, checked_uri: f.original_file.file_identifiers.first, file_id: 'original_file', created_at: 1.day.ago)
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.file_identifiers.first, file_id: 'original_file')
        end

        it "records the fixity check result" do
          expect(subject).to include "passed"
        end
      end

      context "with an id" do
        subject { service_by_id.logged_fixity_status }

        before do
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.file_identifiers.first, file_id: 'original_file')
        end

        it "records the fixity result" do
          expect(subject).to include "passed"
        end
      end
    end
  end
end
