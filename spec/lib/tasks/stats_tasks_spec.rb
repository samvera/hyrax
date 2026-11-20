# frozen_string_literal: true
RSpec.describe 'hyrax:stats:prune_zero_stats' do
  before { load_rake_environment([File.expand_path('../../../lib/tasks/stats_tasks.rake', __dir__)]) }

  it 'keeps only the most recent zero-count row per object, plus all non-zero rows' do
    kept_zero = FileViewStat.create!(file_id: 'abc', views: 0, date: 2.days.ago)
    FileViewStat.create!(file_id: 'abc', views: 0, date: 10.days.ago)
    real_view = FileViewStat.create!(file_id: 'abc', views: 3, date: 5.days.ago)
    other_file_zero = FileViewStat.create!(file_id: 'xyz', views: 0, date: 1.day.ago)

    kept_zero_downloads = FileDownloadStat.create!(file_id: 'abc', downloads: 0, date: 2.days.ago)
    FileDownloadStat.create!(file_id: 'abc', downloads: 0, date: 10.days.ago)

    kept_zero_work = WorkViewStat.create!(work_id: 'work1', work_views: 0, date: 2.days.ago)
    WorkViewStat.create!(work_id: 'work1', work_views: 0, date: 10.days.ago)

    run_task('hyrax:stats:prune_zero_stats')

    expect(FileViewStat.all).to contain_exactly(kept_zero, real_view, other_file_zero)
    expect(FileDownloadStat.all).to contain_exactly(kept_zero_downloads)
    expect(WorkViewStat.all).to contain_exactly(kept_zero_work)
  end

  it 'deletes nothing when DRY_RUN is set' do
    FileViewStat.create!(file_id: 'abc', views: 0, date: 2.days.ago)
    FileViewStat.create!(file_id: 'abc', views: 0, date: 10.days.ago)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DRY_RUN').and_return('true')

    run_task('hyrax:stats:prune_zero_stats')

    expect(FileViewStat.count).to eq(2)
  end

  it 'deletes redundant rows across multiple batches' do
    kept = FileViewStat.create!(file_id: 'abc', views: 0, date: 1.day.ago)
    5.times { |n| FileViewStat.create!(file_id: 'abc', views: 0, date: (n + 2).days.ago) }
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('BATCH_SIZE').and_return('2')

    run_task('hyrax:stats:prune_zero_stats')

    expect(FileViewStat.all).to contain_exactly(kept)
  end
end
