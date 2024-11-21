@IsTest
private class OpportunityTeamMemberEventTest {
	
    @isTest
    static void initialize_test() {
        	Account accObj;
            accObj = new Account();
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';
            insert accObj;
            
            Opportunity optyObj = new Opportunity();
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = System.now().Time();
            optyObj.End_Time__c = System.now().Time()+1;
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            insert optyObj;
        
        	OpportunityTeamMember otm;
            otm = new OpportunityTeamMember();
            otm.OpportunityAccessLevel = 'Edit';
            otm.userId = UserInfo.getUserId();
            otm.OpportunityId = optyObj.Id;
            otm.TeamMemberRole = 'Account Manager';
            otm.Start_Date__c = System.today();
            insert otm;
        
        	OpportunityTeamMemberEvent__e otme = new OpportunityTeamMemberEvent__e();
        	otme.OpportunityId__c = optyObj.Id;
        	Test.startTest();
            
            // Publish test event
            Database.SaveResult sr = EventBus.publish(otme);
                
            Test.stopTest();
        
    }
}