@pending @catalog
Feature: Search Results Pagination
  As a user
  In order to find the documents I'm searching for
  I want to see my search results in an useful way.

  Scenario: Viewing search results
    Given a search result that contains more than 50 results
    When I am on the search results page
    And I am in "List view" mode
    Then I should "List View" in highlight
    And I should see "gallery view" not in highlight 
    And I should see 50 results
    And I should see "search breadcrumb"
    And I should see the "collection id" box
