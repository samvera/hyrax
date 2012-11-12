# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :single_use_link do
    downloadKey "MyString"
    path "MyString"
    itemId "MyString"
    expires "2012-10-23 09:55:25"
  end
end
