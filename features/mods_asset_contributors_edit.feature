@contributors
Feature: Edit Article Contributors
  As a person with edit permissions
  In order to manage the contributor entries (names) in a MODS document
  I want to see and edit the contributors associated with an article

  @overwritten
  Scenario: Viewing contributors in edit mode
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the "First Name" field should contain "GIVEN NAMES"
    And the "Last Name" field should contain "FAMILY NAME"
    And I should see "Author" within "select[rel=person_0_role_text]"
    # And the "role" field for "the 1st person" entry should contain "Author"
    And the "Institution" field should contain "FACULTY, UNIVERSITY"
    And I should see a delete contributor button for "the 1st person entry in hydrangea:fixture_mods_article1"
    
    # Then the "First Name" field for "person_1" should contain "Henrietta"
    # And the "Last Name" field for "person_1" should contain "Lacks"
    # And the "Role" field for "person_1" should contain "Contributor"
    # And the "Institution" field for "person_1" should contain "Baltimore"
    Then I should see "Henrietta"
    And I should see "Lacks"
    And I should see "Contributor" within "select[rel=person_1_role_text]"
    And I should see "Baltimore"
    And I should see a delete contributor button for "the 2nd person entry in hydrangea:fixture_mods_article1"
    
    Then I should see "NSF"
    And I should see "Funder" within "select[rel=organization_0_role_text]"    
    And I should see a delete contributor button for "the 1st organization entry in hydrangea:fixture_mods_article1"
    
    Then I should see "some conference"
    And I should see "Host" within "select[rel=conference_0_role_text]"    
    And I should see a delete contributor button for "the 1st conference entry in hydrangea:fixture_mods_article1"

  @local
  Scenario: Viewing contributors in edit mode
    Given I am logged in as "archivist1"
    And I am on the edit document page for libra-oa:1 
    Then the "First Name" field should contain "Mary"
    And the "Last Name" field should contain "Gibson"
    And the "Institution" field should contain "University of Virginia"

  @overwritten
  Scenario: Viewing contributors in browse mode
    Given I am logged in as "archivist1"
    And I am on the show document page for hydrangea:fixture_mods_article1 
    Then I should see "GIVEN NAMES" within "#contributors_list"
    And I should see "FAMILY NAME" within "#contributors_list"
    And I should see "Creator" within "#contributor_role"
    # And the "role" field for "the 1st person" entry should contain "Author"
    And I should see "FACULTY, UNIVERSITY" within "#contributors_list"
    And I should not see a delete contributor button for "the 1st person entry in hydrangea:fixture_mods_article1"

    # Then the "First Name" field for "person_1" should contain "Henrietta"
    # And the "Last Name" field for "person_1" should contain "Lacks"
    # And the "Role" field for "person_1" should contain "Contributor"
    # And the "Institution" field for "person_1" should contain "Baltimore"
    Then I should see "Henrietta"
    And I should see "Lacks"
    And I should see "Contributor" within "#person_1 #contributor_role"
    And I should see "Baltimore"
    And I should not see a delete contributor button for "the 2nd person entry in hydrangea:fixture_mods_article1"

    Then I should see "NSF"
    And I should see "Funder" within "#organization_0"    
    And I should not see a delete contributor button for "the 1st organization entry in hydrangea:fixture_mods_article1"

    Then I should see "some conference"
    And I should see "Host" within "#conference_0"    
    And I should not see a delete contributor button for "the 1st conference entry in hydrangea:fixture_mods_article1"

  @local
  Scenario: Viewing contributors in browse mode
    Given I am logged in as "archivist1"
    And I am on the show document page for libra-oa:1
    Then I should see "Mary Gibson" within "#contributors_list"
    And I should see "Author" within ".contributor_role"
    And I should see "University of Virginia" within "#contributors_list"
    And I should not see a delete contributor button for "the 1st person entry in libra-oa:1"

 
