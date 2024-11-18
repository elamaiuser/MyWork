/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  10/02/2024				 Kishore Das		        Test class for the class ActiveTemplateController

 *************************************************************************************************************************************************************************************
*/

@isTest
private class ActiveTemplateControllerTest {
    
    @isTest
    static void testGetActiveTemplates() {
        Account testAccount = new Account(Name = 'Test Account',Sponsor_Keyword__c='Test1');
        insert testAccount;
        
        contact c=new contact();
        c.AccountId=testAccount.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        Opportunity testTemplate = new Opportunity(
            Name = 'Test Template',
            AccountId = testAccount.Id,
            Template_Status__c = 'Active',
            Is_Template__C = true,
            StageName='Draft',
            CloseDate=system.today()
        );
        insert testTemplate;
        
       
        
        Test.startTest();
        List<Opportunity> result = activeTemplateController.getActiveTemplates(testAccount.Id);
        Test.stopTest();
        
        assert.areequal(1, result.size(), 'There should be one active template');
    }
    
    @isTest
    static void testUpdateFutureOpportunities() {
        Account testAccount = new Account(Name = 'Test Account', Sponsor_Keyword__c = 'Test Keyword');
        insert testAccount;
        
        Opportunity testTemplate = new Opportunity(
            Name = 'Test Template',
            AccountId = testAccount.Id,
            Template_Status__c = 'Active',
            Is_Template__C = true,
            StageName='Draft',
            CloseDate=system.today()
        );
        insert testTemplate;
        
        contact c=new contact();
        c.AccountId=testAccount.Id;
        c.FirstName='contact12';
        c.Email='abcde@gmail.com';
        c.Primary_Phone__c='Mobile Phone';
        c.Original_Service_Date__c=system.today();
        c.LastName='contact22';
        c.Phone='74747492';
        insert c;
        
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today()+5,
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
            mobileOpp.AccountId = testAccount.Id;
            //mobileOpp.Drive_Site__c = lc.id;
			insert mobileOpp;  
        
        Test.startTest();
        activeTemplateController.updateFutureOpportunities(new List<Id>{testTemplate.Id});
        Test.stopTest();
        
        testTemplate = [SELECT Drive_Keyword__c FROM Opportunity WHERE Id = :testTemplate.Id];
        assert.areequal(testAccount.Sponsor_Keyword__c, testTemplate.Drive_Keyword__c, 'The Drive_Keyword__c should be updated to match the Sponsor_Keyword__c');
        
    }
}