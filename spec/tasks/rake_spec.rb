require 'rake'

describe "Rake tasks" do
  describe "sufia:migrate" do
    let(:namespaced_id) { "sufia:123" }
    let(:corrected_id)  { "123" }
    before do
      load_rake_environment [File.expand_path("../../../tasks/migrate.rake", __FILE__)]
    end

    describe "deleting the namespace from ProxyDepositRequest#work_id" do
      let(:sender) { create(:user) }
      let(:receiver) { create(:user) }
      before do
        ProxyDepositRequest.create(work_id: namespaced_id, sending_user: sender, receiving_user: receiver, sender_comment: "please take this")
        run_task "sufia:migrate:proxy_deposits"
      end
      subject { ProxyDepositRequest.first.work_id }
      it { is_expected.to eql corrected_id }
    end

    describe "deleting the namespace from ChecksumAuditLog#file_set_id" do
      before do
        ChecksumAuditLog.create(file_set_id: namespaced_id)
        run_task "sufia:migrate:audit_logs"
      end
      subject { ChecksumAuditLog.first.file_set_id }
      it { is_expected.to eql corrected_id }
    end
  end

  describe "sufia:user:list_emails" do
    let!(:user1) { FactoryGirl.create(:user) }
    let!(:user2) { FactoryGirl.create(:user) }

    before do
      load_rake_environment [File.expand_path("../../../tasks/sufia_user.rake", __FILE__)]
    end

    it "creates a file" do
      run_task "sufia:user:list_emails"
      expect(File.exist?("user_emails.txt")).to be_truthy
      expect(IO.read("user_emails.txt")).to include(user1.email, user2.email)
      File.delete("user_emails.txt")
    end

    it "creates a file I give it" do
      run_task "sufia:user:list_emails", "abc123.txt"
      expect(File.exist?("user_emails.txt")).not_to be_truthy
      expect(File.exist?("abc123.txt")).to be_truthy
      expect(IO.read("abc123.txt")).to include(user1.email, user2.email)
      File.delete("abc123.txt")
    end
  end
end
