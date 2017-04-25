class ChangeFeaturedWorkGenericFileIdToWorkId < ActiveRecord::Migration[4.2]
  def change
    return unless column_exists?(:featured_works, :generic_file_id)
    rename_column :featured_works, :generic_file_id, :work_id
  end
end
