@show @pending
Feature: List downloads for a document
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Visit Document Downloads Page
    Given I am on the list downloads page for druid:cm234kq4672
    Then I should see a link to download "Feigenbaum_00011502.pdf" from "druid:cm234kq4672"
    And I should see only 1 download link
    
  Scenario: Patron attempts to see all datastreams via Downloads Page
    Given I am on the list downloads page for druid:cm234kq4672
    Then I should see a link to download "Feigenbaum_00011502.pdf" from "druid:cm234kq4672"
    And I should see only 1 download link
  
  Scenario: Donor Visits Document Downloads Page
    Given I am logged in as "francis" on the list downloads page for druid:cm234kq4672 
    Then I should see a link to download "Feigenbaum_00011502.pdf" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_METS.xml" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_TEXT.xml" from "druid:cm234kq4672"
    And I should see 3 download links
    
  Scenario: Donor Visits Document Downloads Page, views all documents
    Given I am logged in as "francis" on the list all downloads page for druid:cm234kq4672 
    Then I should see a link to download "Feigenbaum_00011502.pdf" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_METS.xml" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_TEXT.xml" from "druid:cm234kq4672"
    And I should see a link to download "extProperties" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_0001.xml" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502.md5" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_0001.tif" from "druid:cm234kq4672"
    And I should see a link to download "metadata.csv" from "druid:cm234kq4672"
    And I should see a link to download "Dublin Core Record for this object" from "druid:cm234kq4672"
    And I should see a link to download "Feigenbaum_00011502_0001.jp2" from "druid:cm234kq4672"
    And I should see 10 download links
    
    
    

    
    
    
    
