require 'spec_helper'

describe My::FilesController do

  before :all do
    GenericFile.destroy_all
    Collection.destroy_all
  end

  after :all do
    GenericFile.destroy_all
    Collection.destroy_all
  end

  let(:my_collection) do
    Collection.new(title: 'test collection').tap do |c|
      c.apply_depositor_metadata(@user.user_key)
      c.save!
    end
  end

  let(:shared_file) do
    FactoryGirl.build(:generic_file).tap do |r|
      r.apply_depositor_metadata FactoryGirl.create(:user)
      r.edit_users += [@user.user_key]
      r.save!
    end
  end

  before do
    @user = FactoryGirl.find_or_create(:archivist)
    sign_in @user
    @my_file = FactoryGirl.create(:generic_file, depositor: @user)
    @my_collection = my_collection
    @shared_file = shared_file
    @unrelated_file = FactoryGirl.create(:generic_file, depositor: FactoryGirl.create(:user))
    @wrong_type = Batch.create
  end

  it "should respond with success" do
    get :index
    expect(response).to be_successful
  end

  it "should paginate" do          
    FactoryGirl.create(:generic_file)
    FactoryGirl.create(:generic_file)
    get :index, per_page: 2
    expect(assigns[:document_list].length).to eq 2
    get :index, per_page: 2, page: 2
    expect(assigns[:document_list].length).to be >= 1
  end

  it "shows the correct files" do
    get :index
    # shows documents I deposited
    expect(assigns[:document_list].map(&:id)).to include(@my_file.id)
    # doesn't show collections
    expect(assigns[:document_list].map(&:id)).to_not include(@my_collection.id)
    # doesn't show shared files
    expect(assigns[:document_list].map(&:id)).to_not include(@shared_file.id)
    # doesn't show other users' files
    expect(assigns[:document_list].map(&:id)).to_not include(@unrelated_file.id)
    # doesn't show non-generic files
    expect(assigns[:document_list].map(&:id)).to_not include(@wrong_type.id)
  end

end
