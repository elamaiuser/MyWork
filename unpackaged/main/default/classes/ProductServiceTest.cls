/**
 * @description: This is the Test class for ProductService.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 10/31/2023			    Barnojit Sharma			Error when deslecting Active in Product object (HRP-11082)
 * *****************************************************************************************************************************************************************************************
 **/
@isTest
public class ProductServiceTest {
    
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileSiteRecType = 'Mobile Site';    
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    static String Id_CollectionOperation = '';
    
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Opportunity' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
        recordTypeMap = recordTypeMap( 'Account' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        
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
            Email = 'DRDProfile000@amamama.com',
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
        System.runAs( AdminUser ){
            skedHubBase.BypassInsertTriggers = true;

            List<Account> mobileAccList = new List<Account>();
            
            Account accObj;
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.Internal_Name__c = 'Exavalu';
            accObj.BillingPostalCode = '30622';
            accObj.Account_Manager__c = DRDAMUser.Id;
            
            mobileAccList.add(accobj);
            TriggerHandler.bypass('AccountTriggerHandler');
            insert mobileAccList;
            
            Contact conObj = new Contact();
            conObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            conObj.Email = 'testContact@gmail.com';
			conObj.Original_Service_Date__c = system.today().addDays(3);
            conObj.Primary_Phone__c = 'Mobile Phone';
            conObj.MobilePhone = '752-781-0090';
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type'; 
            
            insert skedTag; 
            
            
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Site_Inspection_Completed_By__c = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' ].Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Contact__c = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND LastName = 'Contact' ].Id;
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
            siteObj.Source__c = 'Custom New Form';
            siteObj.sked_Address_1__c = 'test';
        	siteObj.sked_Outside_stairs__c = 10;
        	siteObj.sked_County__c = 'test';
        	siteObj.sked_State__c = 'test';
        	siteObj.sked_Zip_Code__c = 'test123';
        	siteObj.sked_City__c = 'test';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            TriggerHandler.bypass('SiteTriggerHandler');
            insert siteObj;
            
            Opportunity optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive 01';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today().addDays(56);
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = System.now().Time();
            optyObj.End_Time__c = System.now().Time()+1;
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            optyObj.Drive_Status__c = 'Draft';
            TriggerHandler.bypass('OpportunityTriggerHandler');
            insert optyObj;
            
            
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
                                                        sked_Drive_Site__c = siteObj.id,
                                                        sked_Opportunity__c = optyObj.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = mobileAccList[0].id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED);
        insert testDrive1;
        
            
        }
    }
    
    @isTest 
    static void checkRelaetdDriveDateAndSendNotificationTest() {        
        //Create a product
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Product2 product = new Product2();
        product.Start_Date__c = System.today();
        product.End_Date__c = System.today().addDays(100);
        product.IsActive = true;
        product.Name = 'Test Product 01';
        
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Order order = new Order();
        order.AccountId = [SELECT Id FROM Account WHERE Name ='Exavalu'].Id;
        order.OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        order.Name = 'Test Order 01';
        order.Status = 'Draft';
    	order.EffectiveDate = system.today();
        order.Pricebook2Id =  pricebookId ;
        
        insert order;
                
        
        // Insert PricebookEntry
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = product.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        OrderItem oItem = new OrderItem();
        oItem.OrderId = order.id;
        oItem.Quantity = .5;
        oItem.UnitPrice = .5;
        oItem.Product2id = product.id;
        oItem.PricebookEntryId=standardPrice.id;
        insert oItem;

        Test.startTest();
        
            Product2 productToUpdate = [SELECT Id,End_Date__c FROM Product2 WHERE Name='Test Product 01'];
            productToUpdate.End_Date__c = System.today() + 10;
            update productToUpdate;

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