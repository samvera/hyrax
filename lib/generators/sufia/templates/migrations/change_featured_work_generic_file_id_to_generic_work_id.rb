class ChangeFeaturedWorkGenericFileIdToGenericWorkId < ActiveRecord::Migration
  def change
    return unless column_exists?(:featured_works, :generic_file_id)
    rename_column :featured_works, :generic_file_id, :generic_work_id
  end
end
