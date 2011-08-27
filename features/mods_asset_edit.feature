@edit @articles
Feature: Edit a ModsAsset object
  As a Depositor
  I want to see appropriate information for editing ModsAsset objects
  
  Scenario: Edit Page for Mods Asset
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the "person_0_first_name" field should contain "GIVEN NAMES"    
    And I should see a "Continue" button

  Scenario: Visit Document Edit Page and see the file assets
     Given I am logged in as "archivist1" 
     And I am on the edit files page for libra-oa:1
     And I select "1" from "number_of_files"
     And I press "Continue"
#     Then the "title_info_main_title" field should contain "The Smallest Victims of the "
		 Then I should see "gibson.pdf" within "tr.file_asset"
		 And I should see "Delete" in the file assets list

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydrangea:fixture_mods_article1
    Then I should see a "div" tag with a "class" attribute of "edit-browse"
    
  Scenario: Entering a non-valid embargo date
    Given I am logged in as "archivist1" 
    When I am on the edit additional_info page for hydrangea:fixture_mods_article1
    And I fill in "embargo_embargo_release_date" with "25-25-25"
    And I press "Continue"
    Then I should see "You must enter a valid release date."
    
  Scenario: Entering different date formats for embargo
    Given I am logged in as "archivist1" 
    When I am on the edit additional_info page for hydrangea:fixture_mods_article1
    And I fill in "embargo_embargo_release_date" with "11/1/2010"
    When I press "Continue"
    And I am on the edit additional_info page for hydrangea:fixture_mods_article1
    Then the "embargo_embargo_release_date" field within "#release_date_field" should contain "2010-11-01"
    When I fill in "embargo_embargo_release_date" with "November 1st 2010"
    And I press "Continue"
    When I am on the edit additional_info page for hydrangea:fixture_mods_article1
    Then the "embargo_embargo_release_date" field within "#release_date_field" should contain "2010-11-01"
    # The last 2 lines are just clean up.
    Then I fill in "embargo_embargo_release_date" with ""
    And I press "Continue"

  Scenario: Save and Finish
    Given I am logged in as "archivist1" 
    When I am on the edit additional_info page for hydrangea:fixture_mods_article1
    When I press "Save and Finish"
    Then I should see "Switch to edit view"
    And I should see "Your object has been saved"

  Scenario: html5 valid
    Given I am logged in as "archivist1"
    When I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the page should be HTML5 valid

  # the mockups for Libra did not have a delete confirmation
  @overwritten
  Scenario: Delete Confirmation on Edit Page
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydrangea:fixture_mods_article1 
    Then I should see a "div" tag with an "id" attribute of "delete_dialog_container"
    And I should see "Permanently delete"
