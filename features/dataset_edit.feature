@edit @datasets
Feature: Edit a Dataset
  In order to manage a dataset
  As a researcher
  I want to see & edit a dataset's values


  Scenario: Visit Dataset Edit Page
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_dataset1 
    # Then I should see "Fixture Marine Biology Dataset" within "h1.document_heading"
    Then I should see "Fixture Marine Biology Dataset" within ".title"
    And I should see an inline edit containing "Fixture Marine Biology Dataset"
    

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_dataset1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"
  
  Scenario: Submitting new values
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_dataset1
    And the following should not contain:
        | subject_topic_1 | 5002    |
        | Ecosystem Type  | Coral Reef |
        | data quality    | Nice guy|
    And I fill in the following:
        | subject_topic_1 | 5002    |
        | Ecosystem Type  | Coral Reef |
        | Notes           | Nice guy|
    # When I press "Save Description"
    # Then show me the page
    # Then I should see "Your changes have been saved."
    # And the following should contain:
    #     | subject_topic_1 | 5002    |
    #     | Ecosystem Type  | Coral Reef |
    #     | data quality    | Nice guy|