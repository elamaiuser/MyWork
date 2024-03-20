/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/26/2023				 Kishore Das		        This test class covering BSF_BatchCalendarBuildStatusUpdate for story(HRP-10887)

 *************************************************************************************************************************************************
*/
@isTest
public class BSF_BatchCalendarBuildStatusTest {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static List<Opportunity> opplst = new List<Opportunity>();
    
    @testSetup static void setup() {
        // create Account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu1';
        accobj.Internal_Name__c = 'Exavalu1';
        accobj.BillingPostalCode = '30146';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        // create Contact
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
        optyObj.Drive_Date__c = system.today()+1;
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();        
        optyObj.Anticipated_Registered_Donors__c = 1;   
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Calendar_Build_Status__c=null;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        optyObj.Flow_End_Time_Field__c ='1250';
        optyObj.Flow_Start_Time_Field__c ='0050';
        optyObj.is_template__c = true;
        opplist.add(optyObj);  
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert opplist;
        
        sked_Drive__c driveOnCalendar = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = skedlocationlist[0].id,
                                                        sked_Opportunity__c = opplist[0].id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = mobileAccList[0].id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
        insert driveOnCalendar;
    }
    static testmethod void testBatchMethod() {
        Test.startTest();
        BSF_BatchCalendarBuildStatusUpdate cb = new BSF_BatchCalendarBuildStatusUpdate();
        Database.executebatch(cb);
        Test.stopTest();
        
        Opportunity updatedOpportunity = [SELECT Id,Calendar_Build_Status__c, StageName FROM Opportunity limit 1];
    	//assert.areequal('Unqualified', updatedOpportunity.Calendar_Build_Status__c);
    }
    @isTest
    Public static void Test_Schedule_Class1()
    {
        Test.StartTest();
		
        BSF_BatchCalendarBuildStatusSchedular testsche1 = new BSF_BatchCalendarBuildStatusSchedular(200);
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