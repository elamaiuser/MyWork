@isTest
public class skedEmailHandlerController_Test {

    static testmethod void testConfirmAndView() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Availability__c availability = [SELECT Id, sked_Unique_Key__c, sked_Waitlist_Confirmed__c, sked_Custom_Status__c
                                             FROM sked__Availability__c
                                             LIMIT 1];
        sked__Availability__c updatedAvailability = new sked__Availability__c(Id = availability.Id, 
                                                                              sked__Is_Available__c = FALSE,
                                                                              sked_Waitlist_Confirmed__c = FALSE);
        update updatedAvailability;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedEmailHandler'));
        ApexPages.currentPage().getParameters().put('id', availability.Id);
        ApexPages.currentPage().getParameters().put('action', 'Confirm');
        ApexPages.currentPage().getParameters().put('token', availability.sked_Unique_Key__c);
        
        Boolean resultForConfirmAvaiability = skedEmailHandlerController.confirmAvailability(availability.Id, 'Confirm', availability.sked_Unique_Key__c);
        Boolean resultForViewAvaiability = skedEmailHandlerController.confirmAvailability(availability.Id, 'View', availability.sked_Unique_Key__c);
        
        Test.stopTest();
        Assert.isTrue(resultForViewAvaiability == true);
        Assert.isTrue(resultForConfirmAvaiability == true);
    }
    
    static testmethod void testDecline() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Availability__c availability = [SELECT Id, sked_Unique_Key__c, sked_Waitlist_Confirmed__c, sked_Custom_Status__c
                                             FROM sked__Availability__c
                                             LIMIT 1];
        sked__Availability__c updatedAvailability = new sked__Availability__c(Id = availability.Id, 
                                                                              sked__Is_Available__c = FALSE,
                                                                              sked_Waitlist_Confirmed__c = FALSE);
        update updatedAvailability;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedEmailHandler'));
        ApexPages.currentPage().getParameters().put('id', availability.Id);
        ApexPages.currentPage().getParameters().put('action', 'Declined');
        ApexPages.currentPage().getParameters().put('token', availability.sked_Unique_Key__c);
        
        Boolean resultForDeclineAvaiability = skedEmailHandlerController.confirmAvailability(availability.Id, 'Declined', availability.sked_Unique_Key__c);
        
        Test.stopTest();
        Assert.isTrue(resultForDeclineAvaiability == true);
    }
    
    static testmethod void testInvalidRequest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Job__c testJob1 = [SELECT Id
                                FROM sked__Job__c
                                LIMIT 1];
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedEmailHandler'));
        ApexPages.currentPage().getParameters().put('id', testJob1.Id);
        ApexPages.currentPage().getParameters().put('action', 'Confirm');
        ApexPages.currentPage().getParameters().put('token', 'invalidToken');
        
        skedEmailHandlerController.confirmAvailability(testJob1.Id, 'Confirm', 'invalidToken');
        
        sked__Availability__c availability = [SELECT Id, sked_Unique_Key__c, sked_Waitlist_Confirmed__c, sked_Custom_Status__c
                                             FROM sked__Availability__c
                                             LIMIT 1];
        sked__Availability__c updatedAvailability = new sked__Availability__c(Id = availability.Id, 
                                                                              sked__Is_Available__c = FALSE,
                                                                              sked_Waitlist_Confirmed__c = FALSE);
        update updatedAvailability;
        ApexPages.currentPage().getParameters().put('id', availability.Id);
        ApexPages.currentPage().getParameters().put('action', 'invalidStatus');
        ApexPages.currentPage().getParameters().put('token', availability.sked_Unique_Key__c);
        Boolean resultForInvalidAvaiability = skedEmailHandlerController.confirmAvailability(availability.Id, 'invalidStatus', availability.sked_Unique_Key__c);
        
        skedEmailHandlerController testInstance = new skedEmailHandlerController();
        String testResult = testInstance.getAvailabilityUrl();
        
        Test.stopTest();
        Assert.isTrue(resultForInvalidAvaiability == false);
        Assert.isTrue(String.isNotBlank(testResult));
    }
}