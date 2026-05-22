# This migration comes from bulkrax (originally 20211004170708)
class ChangeBulkraxStatusesErrorMessageColumnTypeToText < ActiveRecord::Migration[5.1]
  def change
    change_column :bulkrax_statuses, :error_message, :text
  end
end
