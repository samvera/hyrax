@file_assets
Feature: Upload file into a document
  In order to add files to a document
  As an editor 
  I want to upload files in the edit form
  
  @nojs
  Scenario: Upload files on dataset edit page
    Given I am logged in as "archivist1"
    And I am on the edit document page for hydrangea:fixture_mods_dataset1
    And I attach the file "spec/fixtures/image.jp2" to "Filedata"
    When I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    And I should see a link to "image.jp2" in the file assets list
    
  Scenario: Upload files on article edit page
    Given I am logged in as "archivist1"
    And I am on the edit document page for hydrangea:fixture_mods_article1
    And I attach the file "spec/fixtures/image.jp2" to "Filedata"
    When I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    And I should see a link to "image.jp2" in the file assets list
  
  @nojs
  Scenario: Upload files on file assets list page
    Given I am logged in as "archivist1"
    And I am on the file asset list page for hydrangea:fixture_mods_dataset1
    And I attach the file "spec/fixtures/image.jp2" to "Filedata"
    When I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    And I should see a link to "image.jp2" in the file assets list
  
  Scenario: Upload files on file asset creation page
    Given I am logged in as "archivist1"
    And I am on the file asset creation page for hydrangea:fixture_mods_dataset1
    And I attach the file "spec/fixtures/image.jp2" to "Filedata"
    When I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    And I should see a link to "image.jp2" in the file assets list
