@isTest
class CloneOpportunityControllerTest {
   public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>(); 
    
    
    
    @isTest
    static void getOpportunityLineItems_test() {
    
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = urole.Id
        );
        
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        // create Account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        accobj.Internal_Name__c = 'Exavalu';       
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
		conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conlist.add(conObj);
        insert conlist;
            
        List<Account_Service_Role__c> accountServRoles = new List<Account_Service_Role__c>();
        Account_Service_Role__c accs = new Account_Service_Role__c();     
        accs.Account__c = accobj.Id;
        accs.Contact__c = conObj.Id;
        accs.Start_Date__c = System.today();
        accs.End_Date__c = System.today() + 10;
        accs.Account_Service_End_Reason__c='Other';
        accs.Account_Service_Role__c = 'Blood Program Leader';
        accountServRoles.add(accs);
        
        // insert sked tag  
        sked__Tag__c skedTag = new sked__Tag__c();
        skedTag.Name = 'Outside';
        skedTag.sked__Type__c = 'Physical Location Type';
        insert skedTag; 
            
        // create sked location
        siterecordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = siterecordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedlocationlist.add(siteObj);
        insert skedlocationlist;
            
        // create Opportunity
        opprecordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = opprecordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = time.newInstance(09, 30, 0, 0);
        optyObj.End_Time__c = time.newInstance(10, 30, 0, 0);
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Flow_Start_Time_Field__c = '1000';
        optyObj.Flow_End_Time_Field__c = '1830';
        optyObj.is_template__c = true;
        opplist.add(optyObj);  
        
        Opportunity optyObj1 = new Opportunity();
        optyObj1.RecordTypeId = optyRecTypeId;
        optyObj1.AccountId = mobileAccList[0].Id;
        optyObj1.Drive_Site__c = skedlocationlist[0].Id;
        optyObj1.Name = 'Test Drive 1';
        optyObj1.StageName = 'Discovery';
        optyObj1.Drive_Date__c = System.today();
        optyObj1.Type_of_Drive__c = 'Mobile';
        optyObj1.CloseDate = System.today();
        optyObj1.Start_Time__c = time.newInstance(09, 30, 0, 0);
        optyObj1.End_Time__c = time.newInstance(10, 30, 0, 0);
        optyObj1.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj1.X2RBC_Projected_Procedures__c = 1;
        optyObj1.WB_Projected_Procedures__c = 2;
        optyObj1.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj1.Platelet_Projected_Procedures__c = 1;
        optyObj1.Flow_Start_Time_Field__c = '1000';
        optyObj1.Flow_End_Time_Field__c = '1830';
        optyObj1.is_template__c = true;
		optyObj1.Parent_Template_Id__c = opplist[0].Id;       
        opplist.add(optyObj1);
                    
            insert opplist;
          try{
               CloneOpportunityController.throwException('error Message'); 
        }Catch(Exception e)
        {
          system.debug('The exception:'+ e);
        }
                        
        Test.startTest();
        
        Opportunity opp = [SELECT StageName, is_template__c, CloseDate, AccountId FROM Opportunity where Id =:opplist[1].id LIMIT 1];
        try{
        String clonedOppRes = CloneOpportunityController.cloneOpportunityFields(opp.Id, JSON.serialize(opp),true);
        }catch(Exception e)
        {
            system.debug('The exception:'+ e);
            //CloneOpportunityController.throwException('error Message');  
        }
        Opportunity activeOppRes = CloneOpportunityController.activeOpportunity(opp.Id);  
        
        Test.stopTest();
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