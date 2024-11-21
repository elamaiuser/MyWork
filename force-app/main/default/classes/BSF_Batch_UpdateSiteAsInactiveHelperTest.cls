@isTest(seeAllData = false)
public class BSF_Batch_UpdateSiteAsInactiveHelperTest {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileSiteRecType = 'Mobile Site';    
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
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
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
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
        System.runAs( AdminUser ){
            
            //create account
        	Account accObj = new Account();
            recordTypeMap = recordTypeMap( 'Account' );
            Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        	accObj.RecordTypeId = accRecTypeId;
        	accObj.Name = 'Exavalu';
            accobj.Internal_Name__c = 'Exavalu';
        	accObj.BillingPostalCode = '30622';            
        	insert accObj;
            
            //create sked_Location__c
            sked__Location__c siteObj = new sked__Location__c();
            recordTypeMap = recordTypeMap( 'sked__Location__c' );
        	Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked_Active__c = true;
            siteObj.sked_Start_Date__c = system.today().addDays(-30);
            siteObj.sked_End_Date__c = system.today();
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Wireless_Policy__c = 'Accepted';            
            siteObj.sked_Address_1__c = 'Test Site Address 1';  
        	siteObj.sked_County__c = 'USA';
        	siteObj.sked_City__c = 'Aubum';
        	siteObj.sked_State__c = 'Alabama';
        	siteObj.sked_Zip_Code__c = '36801';
        	siteObj.sked_Wireless_Policy__c = 'Accepted';
        	siteObj.Source__c = 'Custom New Form';
            insert siteObj;
    }
    }
    
    public static testMethod void testBatchUpdateSiteAsInactive() 
    {
        Test.startTest();
        BSF_Batch_UpdateSiteAsInactiveHelper batchJob = new BSF_Batch_UpdateSiteAsInactiveHelper();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        sked__Location__c updatedSite = [SELECT Id, sked_Active__c FROM sked__Location__c limit 1];
        System.assertEquals(false,updatedSite.sked_Active__c); // site has been made inactive as the end date is reached
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