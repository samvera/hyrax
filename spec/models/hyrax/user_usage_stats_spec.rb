RSpec.describe Hyrax::UserUsageStats do
  subject { create(:user) }

  describe 'with cached stats' do
    let!(:stat_1_day_ago) { UserStat.create!(user_id: subject.id, date: 1.day.ago, file_views: 3, file_downloads: 2, work_views: 5) }
    let!(:stat_2_days_ago) { UserStat.create!(user_id: subject.id, date: 2.days.ago, file_views: 2, file_downloads: 1, work_views: 7) }

    let!(:someone_elses_user_id) { subject.id + 1 }
    let!(:not_my_stat) { UserStat.create!(user_id: someone_elses_user_id, date: 2.days.ago, file_views: 10, file_downloads: 11) }

    describe '#total_file_views' do
      it 'returns the total file views for that user' do
        expect(subject.total_file_views).to eq 5
      end
    end

    describe '#total_file_downloads' do
      it 'returns the total file downloads for that user' do
        expect(subject.total_file_downloads).to eq 3
      end
    end

    describe '#total_work_views' do
      it 'returns the total work views for that user' do
        expect(subject.total_work_views).to eq 12
      end
    end
  end

  describe 'with empty cache' do
    describe '#total_file_views' do
      it 'returns the total file views for that user' do
        expect(subject.total_file_views).to eq 0
      end
    end

    describe '#total_file_downloads' do
      it 'returns the total file downloads for that user' do
        expect(subject.total_file_downloads).to eq 0
      end
    end
  end
end
