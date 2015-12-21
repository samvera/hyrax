require 'spec_helper'

describe Sufia::DefaultWorkService do
  let(:user) { create(:user) }
  let(:upload_set) { UploadSet.create! }
  let(:upload_set_id) { upload_set.id }
  let(:work) { described_class.create(upload_set_id, "test title", user) }

  it "date_uploaded is initialized" do
    expect(work.date_uploaded).not_to be_nil
  end
end
