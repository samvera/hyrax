# frozen_string_literal: true
require 'rake'

RSpec.describe "Rake tasks" do
  describe "hyrax:user:list_emails" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    before do
      load_rake_environment [File.expand_path("../../../lib/tasks/hyrax_user.rake", __FILE__)]
    end

    it "creates a file" do
      run_task "hyrax:user:list_emails"
      expect(File).to exist("user_emails.txt")
      expect(IO.read("user_emails.txt")).to include(user1.email, user2.email)
      File.delete("user_emails.txt")
    end

    it "creates a file I give it" do
      run_task "hyrax:user:list_emails", "abc123.txt"
      expect(File).not_to exist("user_emails.txt")
      expect(File).to exist("abc123.txt")
      expect(IO.read("abc123.txt")).to include(user1.email, user2.email)
      File.delete("abc123.txt")
    end
  end

  describe 'hyrax:collections', :clean_repo do
    describe ':update_collection_type_global_ids' do
      before do
        load_rake_environment [File.expand_path('../../../lib/tasks/collection_type_global_id.rake', __FILE__)]
      end

      context 'with no collections' do
        it 'outputs that 0 collections were updated' do
          run_task 'hyrax:collections:update_collection_type_global_ids'
        end
      end

      context 'with collections' do
        let(:collection_type) { FactoryBot.create(:collection_type) }
        let(:other_collection_type) { FactoryBot.create(:collection_type) }

        let(:collections_with_legacy_gids) do
          [FactoryBot.create(:collection, collection_type_gid: "gid://internal/sometext/#{collection_type.id}"),
           FactoryBot.create(:collection, collection_type_gid: "gid://internal/sometext/#{other_collection_type.id}")]
        end

        before do
          FactoryBot.create_list(:collection, 3, collection_type_gid: collection_type.to_global_id)
          FactoryBot.create_list(:collection, 3, collection_type_gid: other_collection_type.to_global_id)
        end

        it 'updates collections to use standard GlobalId URI' do
          expect { run_task 'hyrax:collections:update_collection_type_global_ids' }
            .to change { collections_with_legacy_gids.map { |col| col.reload.collection_type_gid } }
            .to eq [collection_type.to_global_id.to_s, other_collection_type.to_global_id.to_s]
        end
      end
    end
  end
end
