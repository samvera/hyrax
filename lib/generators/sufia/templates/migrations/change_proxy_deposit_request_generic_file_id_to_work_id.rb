class ChangeProxyDepositRequestGenericFileIdToWorkId < ActiveRecord::Migration
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :generic_id if ProxyDepositRequest.column_names.include?('generic_file_id')
  end
end
