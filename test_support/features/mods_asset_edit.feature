@edit @articles
Feature: Edit a document
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Visit Document Edit Page
    Given I am logged in as "archivist1@example.com" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the "title_info_main_title" field should contain "ARTICLE TITLE" 
    And I should see a "Save Description" button

  Scenario: Visit Document Edit Page and see the file assets
     Given I am logged in as "archivist1@example.com" 
     And I am on the edit document page for libra-oa:1
     Then the "title_info_main_title" field should contain "The Smallest Victims of the " 
		 Then I should see "gibson.pdf" within "tr.file_asset"
		 And I should see a delete button for "libra-oa:1"      

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1@example.com" 
    And I am on the edit document page for hydrangea:fixture_mods_article1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"


  # the mockups for Libra did not have a delete confirmation
  @overwritten
  Scenario: Delete Confirmation on Edit Page
    Given I am logged in as "archivist1@example.com" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then I should see a "div" tag with an "id" attribute of "delete_dialog_container"
    And I should see "Permanently delete"

