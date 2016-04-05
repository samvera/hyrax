require 'spec_helper'
require 'rake'

describe 'Rake tasks' do
  describe 'curation_concerns:migrate' do
    let(:namespaced_id) { 'curation_concerns:123' }
    let(:corrected_id)  { '123' }
    before do
      load File.expand_path('../../../lib/tasks/migrate.rake', __FILE__)
      Rake::Task.define_task(:environment)
    end

    describe 'deleting the namespace from ChecksumAuditLog#file_set_id' do
      before do
        ChecksumAuditLog.create(file_set_id: namespaced_id)
        Rake::Task['curation_concerns:migrate:audit_logs'].invoke
      end
      subject { ChecksumAuditLog.first.file_set_id }
      it { is_expected.to eql corrected_id }
    end
  end
end
