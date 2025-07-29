/* The following test class is covering the following class
  		DriveWorksheet*/

@isTest
public class DriveWorksheet_Test {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
        
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
        
    @isTest
    static void getDrivesOnCalenderItems_test() {
 
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
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.Phone = '1234567890' ;
        accobj.Type = 'Business';
        accobj.Account_Manager__c = AdminUser.id;      
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
        conlist.add(conObj);
        insert conlist;
        
        // create site 
        sked__Location__c site = new sked__Location__c();
        site.Name = 'testSite';
        site.sked_Floor_Description__c = 'Test Floor';
        site.sked_Room_Name__c = 'Test Room';
        site.sked_National_Name__c = 'Test National Name';
        site.sked_Automation_Suitability__c = 'Suitable';
        site.sked_Site_Main_Phone__c = '999-999-9999';
        site.sked_Site_Building_Name__c = 'Test Building';
        site.sked_Physical_Location_Type__c = 'Inside';
        site.sked_Pay_for_Parking__c = 'Other';
        site.sked_Pay_for_Parking_Details__c = 'Other';
        site.sked_Wireless_Policy__c = 'Accepted';
        site.sked_Site_Inspection_Completed_By__c = UserInfo.getUserId();
        site.sked_Room_Size__c = '801-1200 Sq. Ft.';
        site.sked_Staff_Personal_Parking_Directions__c = 'Test';
        site.sked_Address_1__c = 'Test';
        site.sked_Outside_stairs__c = 10;
        site.sked_County__c = 'Test';
        site.sked_State__c = 'Test';
        site.sked_Zip_Code__c = 'test123';
        site.sked_City__c = 'test';
        site.sked_Inside_stairs__c = 10;
        site.sked_Base_Description__c = 'test';
        site.sked_ARC_Vehicle_Parking_Directions__c = 'test';
        site.sked_Directions_From_CollectionOperation__c = 'test';
        site.sked_Start_Date__c = System.today();
        site.sked_End_Date__c = System.today()+5;
        site.Source__c = 'Custom New Form';
        site.sked_Max_Auto_Machines__c = 30.00;
        site.sked_Ready_for_National_Name_Review__c = true;
        insert site;
        
        // create Opportunity
        opprecordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = opprecordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = site.Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Anticipated_Registered_Donors__c = 1;   
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Flow_End_Time_Field__c ='1250';
        optyObj.Flow_Start_Time_Field__c ='0050';
        optyObj.Open_to_Public__c = 'Yes';
        optyObj.Drive_Status__c = 'Tentative';
        opplist.add(optyObj);       
        insert opplist;
        
        //create doc
        skedHubBase.BypassInsertTriggers = true;
        
        TriggerHandler.bypass('skedDriveHandler');
        List<sked_Drive__c> docList = new List<sked_Drive__c>();
        sked_Drive__c doc = new sked_Drive__c();
        doc.sked_Account__c = mobileAccList[0].id;
        doc.Name = 'Test DOC';
        doc.sked_Drive_Site__c = site.id ;
        doc.sked_Opportunity__c = opplist[0].id;
        doc.sked_Start_Time__c = Time.newInstance(1, 2, 3, 4);
        doc.sked_End_Time__c = Time.newInstance(12, 2, 3, 4);
        doc.sked_Drive_Date__c = Date.newInstance(2022, 8, 17);
        doc.sked_Vehicle_Types__c = 'Bus' ;
        doc.sked_Purple_Top_Drive__c = true ;
        doc.sked_Status__c = 'Confirmed';
        docList.add(doc);
        insert docList;
        
        Test.startTest();            
        List<sked_Drive__c> lst = DriveWorksheet.getDriveList(docList[0].id) ;
        List<Account> accList = DriveWorksheet.getAccountList();
        Test.stopTest();

	}
}