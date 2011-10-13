@file_assets
Feature: Upload file into a document
  In order to add files to a document
  As an editor 
  I want to upload files in the edit form
  
  @nojs
  Scenario: Upload files on dataset edit page
    Given I am logged in as "archivist1@example.com"
    When I am on the edit files page for hydrangea:fixture_mods_dataset1
    And I select "1" from "number_of_files"
    And I press "Continue"
    When I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
    And I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    # we shouldn't have to have the step below once we're displaying the contents of the previous steps.
    When I follow "Switch to browse view"
    Then I should see a link to "image.jp2" in the file assets list
    
  Scenario: Upload files on article edit page
    Given I am logged in as "archivist1@example.com"
    When I am on the edit files page for hydrangea:fixture_mods_article1
    Then I select "1" from "number_of_files"
    And I press "Continue"
    When I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
    And I press "Upload File"
    Then I should see "The file image.jp2 has been saved"
    # we shouldn't have to have the step below once we're displaying the contents of the previous steps.
    When I follow "Switch to browse view"
    Then I should see a link to "image.jp2" in the file assets list
    
  Scenario: Not uploading files
    Given I am logged in as "archivist1@example.com"
    When I am on the edit files page for hydrangea:fixture_mods_article1
    Then I select "0" from "number_of_files"
    And I press "Continue"
    Then I should see "Group Permissions"
  
  Scenario: html5 valid uploading files on edit page
    Given I am logged in as "archivist1@example.com"
    When I am on the edit files page for hydrangea:fixture_mods_article1
    Then the page should be HTML5 valid
    And I select "1" from "number_of_files"
    Then I press "Continue"
    Then the page should be HTML5 valid
    And I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
    When I press "Upload File"
    Then the page should be HTML5 valid
  
  # Not sure if the file asset list is valid.  Will the user ever actually be here?  
  # @nojs
  # Scenario: Upload files on file assets list page
  #   Given I am logged in as "archivist1@example.com"
  #   And I am on the file asset list page for hydrangea:fixture_mods_dataset1
  #   And I attach the file "spec/fixtures/image.jp2" to "Filedata[]"
  #   When I press "Upload File"
  #   Then I should see "The file image.jp2 has been saved"
  #   And I should see a link to "image.jp2" in the file assets list
  # 
  # Scenario: Upload files on file asset creation page
  #   Given I am logged in as "archivist1@example.com"
  #   And I am on the file asset creation page for hydrangea:fixture_mods_dataset1
  #   And I attach the file "spec/fixtures/image.jp2" to "Filedata[]"
  #   When I press "Upload File"
  #   Then I should see "The file image.jp2 has been saved"
  #   And I should see a link to "image.jp2" in the file assets list
  # 
  # Scenario: html5 valid uploading files on file assets list page
  #   Given I am logged in as "archivist1@example.com"
  #   And I am on the file asset creation page for hydrangea:fixture_mods_article1
  #   And I attach the file "spec/fixtures/image.jp2" to "Filedata[]"
  #   When I press "Upload File"
  #   Then the page should be HTML5 valid
