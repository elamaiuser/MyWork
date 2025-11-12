/* The below test class is coving the below apex class
 * createPublicityTask
 * */

@isTest(SeeAllData = False)
public class createPublicityTaskTest {
	public static String mobileOppRecType = 'Mobile Opp';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup
    public static void setupData() {
        
        // insert admin user - system admin        
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        insert AdminUser ;
        
        // insert DRD User - AM
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'DRD AM',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
        System.runAs( AdminUser ) {
            insert DRDAMUser;
        }
        
        // required Lists
        List<Opportunity> oppList = new List<Opportunity>();
        List<Order> orderList = new List<Order>();
        
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert opportunity
        recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
		opportunity opp;
        
        opp = new opportunity();
		opp.RecordTypeId = optyRecTypeId;        
        opp.AccountId = testMobileAccount.Id;
        opp.name = 'testOpp1';
        opp.StageName = 'Closed';
        opp.CloseDate = system.today().addDays(30); 
        opp.Drive_Date__c = system.today().addDays(62);
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Account_Manager__c = UserInfo.getUserId();
        opp.Start_Time__c = System.now().Time();
		opp.End_Time__c = System.now().Time() + 1;
		opp.Anticipated_Registered_Donors__c = 1;	
        oppList.add(opp);
        
        opp =new opportunity();
        opp.AccountId = testMobileAccount.Id;
        opp.name = 'testOpp2';
        opp.StageName = 'Discovery';
        opp.CloseDate = system.today().addDays(30); 
        opp.Drive_Date__c = system.today().addDays(63);
        opp.Accept_56_Day_Rule_Violation__c = true;
        opp.Start_Time__c = System.now().Time();
		opp.End_Time__c = System.now().Time() + 1;
		opp.Anticipated_Registered_Donors__c = 1;	
        oppList.add(opp);
        
        insert oppList;  
        
        Order od ;
        od = new Order();
        od.AccountId = testMobileAccount.Id;
        od.OpportunityId = oppList[0].Id;
        od.EffectiveDate = system.today();
        od.Status = 'Draft';
        orderList.add(od);
        
        od = new Order();
        od.AccountId = testMobileAccount.Id;
        od.OpportunityId = oppList[1].Id;
        od.EffectiveDate = system.today();
        od.Status = 'Draft';
        orderList.add(od);
        
        insert orderList;
    }
    
    @isTest
    public static void createTask_Test(){
        
        List<Opportunity> oppList = [select id,stageName,drive_date__c, Account_Manager__c,ownerId from Opportunity WHERE Is_Template__c = false];
        List<Order> orderList = [select id,EffectiveDate,OpportunityId from order];
        
        List<createPublicityTask.getValues> dataList = new List<createPublicityTask.getValues>();
        
        createPublicityTask.getValues dataObj = new createPublicityTask.getValues();
        dataObj.orderId = orderList[0].id;
        dataObj.accountManagerId = oppList[0].Account_Manager__c != NULL ? oppList[0].Account_Manager__c : oppList[0].ownerId;
        dataObj.driveDate = oppList[0].drive_date__c;
        dataObj.stageName = oppList[0].StageName;
        
        dataList.add(dataObj);
        
        createPublicityTask.getValues dataObj1 = new createPublicityTask.getValues();
        dataObj1.orderId = orderList[1].id;
        dataObj1.accountManagerId = oppList[1].Account_Manager__c != NULL ? oppList[1].Account_Manager__c : oppList[1].ownerId;
        dataObj1.driveDate = oppList[1].drive_date__c;
        dataObj1.stageName = oppList[1].StageName;
        
        dataList.add(dataObj1);
        
        Test.startTest();
        createPublicityTask.stageCheckAndTaskCreation(dataList);
        Test.stopTest();
        
        List<Task> taskList = [Select id,ActivityDate,OwnerId,Subject from Task where Subject='Publicity Review Needed'];
        
        System.assertEquals(1, taskList.size()); // for the 2nd opportunity - task won't be created
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
}