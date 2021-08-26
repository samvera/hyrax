class UserPinnedCollectionController < ApplicationController
  
  def create
    UserPinnedCollection.create(user_id: params[:user_id], collection_id: params[:collection_id])
    redirect_to dashboard_path  
  end

  def destroy
    @user_pinned_collection = UserPinnedCollection.find(params[:id])
    @user_pinned_collection.destroy
  end
  
end