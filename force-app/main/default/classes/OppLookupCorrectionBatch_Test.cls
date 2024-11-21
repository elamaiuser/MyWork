@isTest
public class OppLookupCorrectionBatch_Test 
{
	@testSetup
    public static void setup()
    {
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        Account mobileAcc2 = new Account(
            name = 'Test Account 2',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = 'PO BOX 1', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421'
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
        insert accList;
        
        }
    @isTest static void OppLookupCorrectionBatchAll()
    {
        Account acc =[select Id from Account Limit 1];
    opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(22),
        	CloseDate = System.today().addDays(18),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= acc.id);
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
         //delete apaExcep;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Insert opp;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        
        test.startTest();
        BSF_Batch_OppLookupCorrection batch = new BSF_Batch_OppLookupCorrection();
        Database.executeBatch(Batch);
        test.StopTest();
        Opportunity opty = [select id,Owner.Name from Opportunity where Id =:opp.Id];
        assert.isTrue(opty.Owner.Name=='Drd System User');
    }
    
    @isTest static void OppLookupCorrectionBatchSpecificOpp()
    {
        Account acc =[select Id from Account Limit 1];
    opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(22),
        	CloseDate = System.today().addDays(18),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= acc.id);
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
         //delete apaExcep;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Insert opp;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        
        test.startTest();
        BSF_Batch_OppLookupCorrection batch = new BSF_Batch_OppLookupCorrection(new Set<Id>{opp.Id});
        Database.executeBatch(Batch);
        test.StopTest();
    }
    
    @isTest static void OppLookupCorrectionBatchSpecificDriveDate()
    {
        Account acc =[select Id from Account Limit 1];
    opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(22),
        	CloseDate = System.today().addDays(18),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= acc.id);
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
         //delete apaExcep;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Insert opp;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        
        test.startTest();
        BSF_Batch_OppLookupCorrection batch = new BSF_Batch_OppLookupCorrection(opp.Drive_Date__c-1,opp.Drive_Date__c+1);
        Database.executeBatch(Batch);
        test.StopTest();
    }
}