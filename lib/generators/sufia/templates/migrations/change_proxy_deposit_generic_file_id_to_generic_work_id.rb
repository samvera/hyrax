class ChangeProxyDepositGenericFileIdToGenericWorkId < ActiveRecord::Migration
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :generic_work_id
  end
end
