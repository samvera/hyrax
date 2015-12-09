class ChangeProxyDepositRequestPidToGenericFileId < ActiveRecord::Migration
  def change
    rename_column :proxy_deposit_requests, :pid, :generic_file_id
  end
end
