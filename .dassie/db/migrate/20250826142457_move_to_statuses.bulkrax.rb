# This migration comes from bulkrax (originally 20200819054016)
class MoveToStatuses < ActiveRecord::Migration[5.1]
  def change
    Bulkrax::Importer.find_each do |i|
      add_status(i)
    end

    Bulkrax::Exporter.find_each do |i|
      add_status(i)
    end

    Bulkrax::Entry.find_each do |i|
      add_status(i)
    end
  end

  def add_status(i)
    return if i.statuses.present?
    if i.last_error
      i.statuses.create(
        status_message: 'Failed',
        runnable: i.last_run,
        error_class: i.last_error['error_class'],
        error_message: i.last_error['error_message'],
        error_backtrace: i.last_error['error_trace']
      )
    else
      i.statuses.create(status_message: 'Complete', runnable: i.last_run)
    end
  end
end
