require 'rake'

describe "Rake tasks" do
  describe "hyrax:user:list_emails" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    before do
      load_rake_environment [File.expand_path("../../../lib/tasks/hyrax_user.rake", __FILE__)]
    end

    it "creates a file" do
      run_task "hyrax:user:list_emails"
      expect(File.exist?("user_emails.txt")).to be_truthy
      expect(IO.read("user_emails.txt")).to include(user1.email, user2.email)
      File.delete("user_emails.txt")
    end

    it "creates a file I give it" do
      run_task "hyrax:user:list_emails", "abc123.txt"
      expect(File.exist?("user_emails.txt")).not_to be_truthy
      expect(File.exist?("abc123.txt")).to be_truthy
      expect(IO.read("abc123.txt")).to include(user1.email, user2.email)
      File.delete("abc123.txt")
    end
  end
end
