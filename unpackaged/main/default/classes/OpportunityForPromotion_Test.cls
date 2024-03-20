/* This test class is covering the following class
 * OpportunityForPromotion
 * */

@isTest
public class OpportunityForPromotion_Test {
    
	public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
	public static String mobileOppRecType = 'Mobile Opp';
	public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @isTest static void method1()
    {
        // create user 		
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
        
        //UserRole urole  = [select id from userrole where developername =: rolename ];
        
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
		recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        List<Account> mobileAccList = new List<Account>();       
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.Type = 'Business';
        accobj.BillingPostalCode = '30146';        
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
			
        // create sked location
		recordTypeMap = recordTypeMap( 'sked__Location__c' );
		Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
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
        siteObj.sked_Address_1__c = 'test';
        siteObj.sked_County__c = 'test';
        siteObj.sked_State__c = 'test';
        siteObj.sked_Zip_Code__c = 'test123';
        siteObj.sked_City__c = 'test';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.sked_Room_Size__c = '801-1200 Sq. Ft.';
		skedlocationlist.add(siteObj);
		insert skedlocationlist;
			
	
        // create collection operation
        List<Biomed_Collection_Op_Center__c> collectionOppList = new List<Biomed_Collection_Op_Center__c>();
        Biomed_Collection_Op_Center__c collectionOpp = new Biomed_Collection_Op_Center__c();
        collectionOpp.Name = 'Test Collection Operation';
        collectionOpp.sked_Breakdown_Time_Threshold__c = 15;
        collectionOpp.sked_Lunch_Break_Duration_Mobile__c = '30';
        collectionOpp.sked_Lunch_Break_Duration_Fixed_Site__c = '30';
        collectionOpp.sked_Unpaid_Lunch_Break_Duration__c = 30;
        collectionOpp.sked_Maximum_Shift_Length_Threshold__c = 480 ;
        collectionOpp.sked_Setup_Time_Threshold__c = 15;
        collectionOppList.add(collectionOpp);
        insert collectionOppList;
        
        // create district
        List<District__c> districtList = new List<District__c>();
        District__c districts = new District__c();
        districts.Name = 'Test District';
        districts.Collection_Operation__c = collectionOppList[0].id;
        districtList.add(districts);
        insert districtList;
        
        // create donor service region
        List<Collections_Region__c> regionList = new List<Collections_Region__c>();
        Collections_Region__c regions = new Collections_Region__c();
        regions.Name = 'Test Donor Service Region';
        regionList.add(regions);
        insert regionList;
        
        //create collections zipcode
        List<Collections_Territory__c> collectionZipcodeList = new List<Collections_Territory__c>();
        Collections_Territory__c collZipcodes = new Collections_Territory__c();
        collZipcodes.Zip__c = 'Test456';
        collZipcodes.Collection_Operation__c = collectionOppList[0].id;       
        collZipcodes.District__c = districtList[0].id;
        collZipcodes.Region__c = regionList[0].id;
        collectionZipcodeList.add(collZipcodes);
        insert collectionZipcodeList;
        
        
        
        //create opportunity
        recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
		List<Opportunity> opplist = new List<Opportunity>();
		Opportunity optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = mobileAccList[0].Id;
		optyObj.Drive_Site__c = skedlocationlist[0].Id;
		optyObj.Name = 'Test Drive 1';
		optyObj.StageName = 'Discovery';
		optyObj.Drive_Date__c = System.Today().addDays(7);
        optyObj.is_template__c = true;
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+1;
		optyObj.Anticipated_Registered_Donors__c = 1;
        optyObj.Collections_Zip_Code__c = collectionZipcodeList[0].id;
        opplist.add(optyObj);
		insert opplist;
        
        // create promotion
        List<Promotion__c> promotionList = new List<Promotion__c>();
        Promotion__c promotions = new Promotion__c();
        promotions.Name = 'Test Promotion';
        promotions.Quantity__c = 10;
        promotions.End_Date__c = system.today().addDays(10);
        promotions.Start_Date__c = system.today();
        promotionList.add(promotions);
        insert promotionList;
 
        System.runAs( AdminUser){
            
            test.startTest();
            	List<OpportunityForPromotion.OpportunityDriveClass> op = OpportunityForPromotion.getRegionDistricCollOpp();
            
            	// 1. all opp when region null 
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhenRegionNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id , null , null , null , null , 'Test Collection Operation' );
            
            	// 2. all opp when district not null 
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhenDistrictNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id , null , null , null , 'Test District' , null );
            
            	// 3. all opp when region not null , coll opp null 
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhenRegionNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id , null , null , 'Test Donor Service Region' , null , null);
            	
            	// 4. all opp when region and district not null , coll opp null
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhencolOppNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id , null , null , 'Test Donor Service Region' , 'Test District' , null );
            	
            	// 5. all opp when district and coll opp not null , region null
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhenDistrictColOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , null , null , 'Test District' , 'Test Collection Operation');
            	
            	// 6. all opp when region and coll opp not null , district null
            	List<OpportunityForPromotion.OpportunityDriveClass> opWhenRegionColOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , null , 'Test Donor Service Region' , null , 'Test Collection Operation');
            	
            	// 7. all opp when region , district and coll opp not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenDistrictRegionColOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , null , 'Test Donor Service Region' , 'Test District' , 'Test Collection Operation');
            	
            	// 8. all opp when account type and coll opp not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeColOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , null , null , 'Test Collection Operation');
            
            	// 9. all opp when account type and district not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeDistrictNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , null , 'Test District' , null);
            
            	// 10. all opp when account type and region not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeRegionNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , 'Test Donor Service Region' , null , null);
				
            	// 11. all opp when account type , region , district not null and coll opp null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeRegionDistrictNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , 'Test Donor Service Region' , 'Test District' , null);

            	// 12. all opp when account type , district and coll opp not null and region null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeDistrictCollOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , null , 'Test District' , 'Test Collection Operation');
				
            	// 13. all opp when account type , region and coll opp not null and district null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeRegionCollOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , 'Test Donor Service Region' , null , 'Test Collection Operation');
            	
            	// 14. all opp when record type and collection operation not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeCollOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , null , null , 'Test Collection Operation');

            	// 15. all opp when record type and district not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeDistrictNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , null , 'Test District' , null);
            
				// 16. all opp when record type and region not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeRegionNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , 'Test Donor Service Region' , null , null);            
            
            	// 17. all opp when record type , region , district not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeRegDistrictNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , 'Test Donor Service Region' , 'Test District' , null);
            
            	// 18. all opp when record type , district , coll opp not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeDistrictCollOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , null , 'Test District' , 'Test Collection Operation');
            	
            	// 19. all opp when record type , region , coll opp not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeRegCollOppNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , 'Test Donor Service Region' , null , 'Test Collection Operation');
            	
            	//20. all opp when account type not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAccTypeNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , null , null , null , null);
            	
            	//21. all opp when record type not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, null , 'Mobile Opp' , null , null , null);
            
            	// 22. all opp when record type and account type not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenRecTypeAccTypeNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , 'Mobile Opp' , null , null , null);
            	
            	//23. all opp when all not null
            	List<OpportunityForPromotion.OpportunityDriveClass> oppWhenAllNotNull = OpportunityForPromotion.getOpptiesForPromotion(promotionList[0].id, 'Business' , 'Mobile Opp' , 'Test Donor Service Region' , 'Test District' , 'Test Collection Operation');
            
            	string resp = OpportunityForPromotion.applyOppPromotion(JSON.serialize(op) , promotionList[0].id);
            	system.assertEquals('success', resp);
            test.stopTest();
        }
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