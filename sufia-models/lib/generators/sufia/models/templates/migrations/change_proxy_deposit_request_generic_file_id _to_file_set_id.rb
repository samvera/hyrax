class ChangeProxyDepositRequestGenericFileIdToFileSetId < ActiveRecord::Migration
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :file_set_id
  end
end
