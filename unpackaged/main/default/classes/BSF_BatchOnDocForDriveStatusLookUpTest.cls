//Test class for BSF_BatchOnDocForDriveStatusLookUp
@isTest
public class BSF_BatchOnDocForDriveStatusLookUpTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    static String Id_CollectionOperation = '';
    
    @isTest static void DriveStatusLookUp() {
        skedHubBase.BypassInsertTriggers = true;
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
             LocaleSidKey = 'en_US'
             
        );
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        // create Account
        // recordTypeMap = recordTypeMap( 'Account' );
        //Id recTypeId = recordTypeMap.get(mobileAccRecType);
       //System.debug( 'recTypeId is ' + recTypeId );
        List<Account> AccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
       // accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        accobj.Internal_Name__c = 'Exavalu';       
        AccList.add(accobj);
        insert AccList;
        
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = AccList[0].Id ;
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
            
        // insert sked tag  
        sked__Tag__c skedTag = new sked__Tag__c();
        skedTag.Name = 'Outside';
        skedTag.sked__Type__c = 'Physical Location Type';
        insert skedTag; 
        
        // create sked location
        //siterecordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = siterecordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        //siteObj.RecordTypeId = siteRecTypeId;
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
        siteObj.sked_Site_Main_Phone__c = '999-999-9999';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedlocationlist.add(siteObj);
        triggerHandler.bypass('SiteTriggerHandler');
        insert skedlocationlist;
        
        // create Opportunity
        Id optyRecTypeId = opprecordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        //optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = AccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c =Time.newInstance(7, 0, 0, 0);
        optyObj.End_Time__c = Time.newInstance(17, 0, 0, 0);
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 2;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Is_template__c=false;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Related_Scheduled_Drive__c = null;
        
        opplist.add(optyObj);  
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert opplist;
        Assert.areNotEqual(null,opplist[0].Id,'Opportunity not inserted');
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
            insert testCollectionOperation1;
            Id_CollectionOperation = testCollectionOperation1.Id;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = skedlocationlist[0].id,
                                                        sked_Opportunity__c = opplist[0].id,
                                                        sked_Type_of_Drive__c = 'Mobile',
                                                        sked_Account__c = AccList[0].id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_2RBC_Projected_Procedures__c = 2,
                                                        sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
        triggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        insert testDrive1;
        Assert.areNotEqual(null,testDrive1.Id,'DOC not inserted');
        Assert.areNotEqual(null,testDrive1.sked_Opportunity__c,'Opportunity not linked');
        
        Opportunity updatedOpp1 = [SELECT Id, Related_Scheduled_Drive__c FROM Opportunity WHERE Id = :opplist[0].Id LIMIT 1];
        updatedOpp1.Related_Scheduled_Drive__c=testDrive1.id;
        //update updatedOpp1;
        
        system.debug('updatedOpp1 '+updatedOpp1);

        List<sked_Drive__c> getDataDOC = [SELECT Id, Name, sked_Opportunity__r.Related_Scheduled_Drive__c 
                                            from sked_Drive__c where sked_Opportunity__r.Related_Scheduled_Drive__c=null 
                                            AND sked_Opportunity__r.Is_template__c=false];
        Assert.areNotEqual(0,getDataDOC.size(),'No data Found');
    
        Test.startTest();
        BSF_BatchOnDocForDriveStatusLookUp batch1 = new BSF_BatchOnDocForDriveStatusLookUp();
        Database.executeBatch(batch1);
        Test.stopTest();
    
        Opportunity updatedOpp = [SELECT Id, Related_Scheduled_Drive__c FROM Opportunity WHERE Id = :opplist[0].Id LIMIT 1];

        // Assert that the Related_Scheduled_Drive__c field has been updated correctly
        System.assertEquals(testDrive1.Id, updatedOpp.Related_Scheduled_Drive__c, 'Related_Scheduled_Drive__c should be updated');
    }
    @isTest
    Public static void Test_Schedule_Class1()
    {
        Test.StartTest();
        
        BSF_BatchOnDocForDriveStatusSchedule testsche1 = new BSF_BatchOnDocForDriveStatusSchedule(200);
        String sch1 = '0 0 23 * * ?';
        system.schedule('Test schedule class1', sch1, testsche1 );
        Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class1'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class1');
    }
    
    static testMethod void testParameterizedConstructor() {
        Test.startTest();
        BSF_BatchOnDocForDriveStatusLookUp batch1 = new BSF_BatchOnDocForDriveStatusLookUp(system.today(), system.today().addDays(20), null, null);
        Database.executeBatch(batch1);
        Test.stopTest();
    }
}