// test class for UpdateCallListRecipientBatch
@isTest
public class UpdateCallListRecipientBatch_Test {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static List<Opportunity> opplst = new List<Opportunity>();

    @testSetup static void setup() {
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu1';
        accobj.Internal_Name__c = 'Exavalu1';
        accobj.BillingPostalCode = '30146';        
        mobileAccList.add(accobj);
        triggerHandler.bypass('AccountTriggerHandler');
        insert mobileAccList;
        
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test1';
        conObj.LastName = 'Contact2';
        conObj.Email = 'testContac2t@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-783-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContaet@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-783-0090';
        conlist.add(conObj);
        insert conlist;
        
        // create sked location
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = siteRecTypeId;
        siteObj.Name = 'Test Site1';
        siteObj.sked__Address__c = 'Test Site Address2';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building1';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description1';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        //siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description2';
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
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.drive_status__c = 'Draft';
        optyObj.Source__c = 'Calendar Build';
        //date drivedate = Date.newInstance(2023, 11, 17);
        optyObj.Drive_Date__c = system.today()+2;
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();        
        optyObj.Anticipated_Registered_Donors__c = 1;   
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Calendar_Build_Status__c=null;
        optyObj.Call_List_Recipient_Exist__c=false;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Flow_End_Time_Field__c ='1250';
        optyObj.Flow_Start_Time_Field__c ='0050';
        optyObj.is_template__c = true;
        opplist.add(optyObj);  
        
        
        Opportunity optyObj1 = new Opportunity();
        optyObj1.RecordTypeId = optyRecTypeId;
        optyObj1.AccountId = mobileAccList[0].Id;
        optyObj1.Drive_Site__c = skedlocationlist[0].Id;
        optyObj1.Name = 'Test Drive';
        optyObj1.StageName = 'Discovery';
        optyObj1.drive_status__c = 'Draft';
        optyObj1.Source__c = 'Calendar Build';
        //date drivedate = Date.newInstance(2023, 11, 17);
        optyObj1.Drive_Date__c = system.today()+2;
        optyObj1.Type_of_Drive__c = 'Mobile';
        optyObj1.CloseDate = System.today();        
        optyObj1.Anticipated_Registered_Donors__c = 1;   
        optyObj1.X2RBC_Projected_Procedures__c = 1;
        optyObj1.WB_Projected_Procedures__c = 2;
        optyObj1.Calendar_Build_Status__c=null;
        optyObj1.Call_List_Recipient_Exist__c=true;
        optyObj1.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj1.Platelet_Projected_Procedures__c = 1;
        optyObj1.Flow_End_Time_Field__c ='1250';
        optyObj1.Flow_Start_Time_Field__c ='0050';
        optyObj1.is_template__c = true;
        opplist.add(optyObj1);  
        insert opplist;
    }
    static testmethod void testBatchMethod() {
        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = con.Id;
        ocr.OpportunityId = op.Id;
        ocr.IsPrimary = true;
        ocr.Role = 'Call List Recipient';
        insert ocr;
        
        Test.startTest();
        UpdateCallListRecipientBatch cb = new UpdateCallListRecipientBatch();
        Database.executebatch(cb);
        Test.stopTest();
        
        Opportunity updatedOpportunity = [SELECT Id,Call_List_Recipient_Exist__c, StageName FROM Opportunity limit 1];
        assert.areequal(true, updatedOpportunity.Call_List_Recipient_Exist__c);
    }
    
    @isTest
    Public static void Test_Schedule_Class1()
    {
        Test.StartTest();
        
        UpdateCallListRecipientBatchSchedule testsche1 = new UpdateCallListRecipientBatchSchedule(200);
        String sch1 = '0 0 23 * * ?';
        system.schedule('Test schedule class1', sch1, testsche1 );
        Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class1'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class1');
    }
    
    
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