/* Modification Log 
 * 
 * Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 09/26/2023			Kishore Das 			Test class for publicityReportNewPortfoliosController
 *****************************************************************************************************************************************************************************
*/
@isTest
public class publicityReportNewPortfoliosTest {
	static String id_opp = '';
    static String id_acc = '';
    static String id_site = '';
    private static void prepareDataset(){
        String rolename = 'West_BDM';
        String mobileOppRecType = 'Mobile Opp';
        String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';    
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
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
        
        //insert AdminUser ;
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
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
            List<Account> mobileAccList = new List<Account>();
            
            Account accObj;
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';
			accObj.Internal_Name__c = 'TEST';            
            mobileAccList.add(accobj); 
            
            
            insert mobileAccList;
            
            List<AccountTeammember> atmList = new List<AccountTeammember>();
            AccountTeammember atm;
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = DRDAMUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Account Specialist';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            insert atmList;
            
            Contact conObj = new Contact();
            conObj.AccountId = mobileAccList[0].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            conObj.Email = 'test.barno@mailinator.com';
            conObj.Primary_Phone__c = picklistValues('Contact','Primary_Phone__c');
            conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
            conObj.HomePhone = '222-222-3333';
            conObj.MobilePhone = '222-222-3333';
            conObj.OtherPhone = '222-222-3333';
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type';             
            insert skedTag; 
                       
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked_Address_1__c = 'Test Site Address';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_City__c = 'Test Site City';
            siteObj.sked_State__c = 'Test Site State';
            siteObj.sked_Zip_Code__c = '4000';
            siteObj.sked_County__c = 'USA';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Site_Inspection_Completed_By__c = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' ].Id;
            siteObj.sked_Date_Site_Inspection_Completed__c = Date.Today(); // added during HRP-9324 changes
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
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.Source__c = 'Custom New Form';
            insert siteObj;
            id_site = siteObj.id;
            
            List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
            
            BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
            Portland_OR_AM_01.Name='Portland OR AM 01';
            Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
            Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
            Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
            Portland_OR_AM_01.Territory_Portfolio__c=false;			
            bsfPortf.add(Portland_OR_AM_01);
            
            
            
            BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
            Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
            Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
            Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
            Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Portfolio_Type__c='District Manager';
            Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
            Sickle_Cell_AM_04.Territory_Portfolio__c=false;
            bsfPortf.add(Sickle_Cell_AM_04);
            
            insert bsfPortf;
            
            List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
            
            Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
            assign1.Assignment_Type__c = 'District Manager';
            assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign1.End_Date__c = Date.Today().addDays(10);
            assign1.Start_Date__c = Date.Today().addDays(-10);
            assign1.User__c = DRDAMUser.Id;
            portfAssignList.add(assign1);
            
            Portfolio_Assignment__c assign2 = new Portfolio_Assignment__c();
            assign2.Assignment_Type__c = 'District Manager';
            assign2.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign2.End_Date__c = Date.Today().addDays(10);
            assign2.Start_Date__c = Date.Today().addDays(-10);
            assign2.User__c = DRDAMUser.Id;
            portfAssignList.add(assign2);
            
            insert portfAssignList;
            id_acc = mobileAccList[0].Id;
            
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = mobileAccList[0].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery'; 
            optyObj.Drive_Status__c = 'Draft'; 
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
            optyObj.End_Time__c =  Time.newInstance(18, 30, 2, 20);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            optyObj.Call_List_Recipient_Exist__c = true;            
            oppsobjlist.add( optyObj );
            insert oppsobjlist;
            id_opp = oppsobjlist[0].id;

            Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
            insert testCollectionOperation1;

            

            sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = oppsobjlist.get(0).Id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = mobileAccList.get(0).Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT);
            insert testDrive1;
            sked_Drive_Shift__c shiftData = new sked_Drive_Shift__c(Name = 'test shift 1',
                                                                    sked_Max_Donor_Capacity__c = 25,
                                                                    sked_2RBC_Projected_Procedures__c = 6,
                                                                    sked_WB_Projected_Procedures__c = 6,
                                                                    sked_Staff_Setup__c = 15,
                                                                    sked_Equipment_Allocated__c = 4,
                                                                    sked_Lunch_Break_Start_Time__c = Time.newInstance(8, 0, 0, 0),
                                                                    sked_Lunch_Break_End_Time__c = Time.newInstance(9, 0, 0, 0),
                                                                    sked_Drive__c = testDrive1.Id,
                                                                    sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                    sked_End_Time__c = Time.newInstance(12, 0, 0, 0));
            insert shiftData;
            sked_Drive_Delivery_Job__c drivejob = new sked_Drive_Delivery_Job__c(sked_Drive__c = testDrive1.Id);
            insert drivejob;
            sked__Region__c reg = new sked__Region__c(Name = 'ABCD',
                                                        sked__Timezone__c = 'America/New_York');
            insert reg;
            String rll = picklistValues('sked__Job__c','sked_Resource_Role__c');
            sked__Job__c skedjob = new sked__Job__c(sked_Drive_Shift__c = shiftData.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Resource_Role__c = rll);
            insert skedjob;
        }        
        
    }
    //Method to get the map of recordType Name as key and recordTypeId as value 
    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
    //Method to get the one picklist value of the Sobject field
    private static String picklistValues(String objectName, String fieldName) {
        String result;

        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }

        return result;
    }
    
    @isTest static void testReport1()
    {
        
        //skedTriggerHub.BypassInsertTriggers = true; commented during HRP-9324 changes
        skedHubBase.BypassInsertTriggers = true; // added during HRP-9324 changes
        
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OrderTriggerHandler');
        TriggerHandler.bypass('OrderItemTriggerHandler');
        TriggerHandler.bypass('skedDriveHandler');
		TriggerHandler.bypass('AccountTriggerHandler');
        
        prepareDataset();
                
        // create product and pricebook
		List<Product2> productlist = new List<Product2>(); 
		Product2 prod1 = new Product2(Name = 'Pint Size Heroes - Donor Sign In Sheet',Family = 'Education',isActive=true,Product_Id__c='PSH.Oth011',Start_Date__c=System.today()-10,End_Date__c=System.today()+5000);
       
        // HRP-10307 - Adding different products for concatenation        
        Product2 prod2 = new Product2(Name = 'Power Red 11 x 17 Poster',Family = 'General;Power Red',isActive=true,Product_Id__c='ATC.Size001b',Start_Date__c=System.today()-10,End_Date__c=System.today()+5000);
        Product2 prod3 = new Product2(Name = 'Theme- Seasonal',Family = 'Theme',isActive=true,Product_Id__c='Theme001',Start_Date__c=System.today()-10,End_Date__c=System.today()+5000);
        Product2 prod4 = new Product2(Name = 'Size - 8 1/2 x 11 Fliers-Electronic',Family = 'Theme;Education;Diversity;General',isActive=true,Product_Id__c='Size005.e',Start_Date__c=System.today()-10,End_Date__c=System.today()+5000);
        productlist.add(prod1);
        productlist.add(prod2);
        productlist.add(prod3);
        productlist.add(prod4);
		insert productlist;
       
        Id pricebookId = Test.getStandardPricebookId();
       
	    // create Pricebook entry
		List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        pentrylist.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,UnitPrice = 0.01, IsActive = true));
		pentrylist.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[1].Id,UnitPrice = 0.01, IsActive = true));
        pentrylist.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[2].Id,UnitPrice = 0.01, IsActive = true));
        pentrylist.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[3].Id,UnitPrice = 0.01, IsActive = true));
		insert pentrylist;
			
        // create order 
        List<Order> orderlist = new List<Order>();
        Order o = new Order(name='Order 1',AccountId= id_acc,OpportunityId = id_opp,Publicity_Submitted__c = false,Publicity_Approved__c = false,
                            Material_Recipient_Type__c = 'Same',Material_Recipient__c = 'Account Manager',EffectiveDate=system.today(),
                            status='draft',Pricebook2Id =  pricebookId,Publicity_Approved_Date__c=System.today()-5);
        orderlist.add(o);
        
        o = new Order(name='Test2',AccountId= id_acc,OpportunityId = id_opp,Publicity_Submitted__c = false,Publicity_Approved__c = false,
                      Material_Recipient_Type__c = 'Same',Material_Recipient__c = 'Account Manager',EffectiveDate=system.today(),
                      status='draft',Pricebook2Id =  pricebookId,Publicity_Approved_Date__c=System.today()-4);
        orderlist.add(o);
        insert orderlist;
        
        List<Order> orderlist1 = [select id,Publicity_Approved__c from order where id=:orderlist[0].id or id=:orderlist[1].id];
        
        orderlist1 [0].Publicity_Approved__c = true;
        orderlist1 [1].Publicity_Approved__c = true;
        update orderlist1;
       
        List<OrderItem> oitemlist = new List<OrderItem>();
        OrderItem oi = new OrderItem(OrderId= orderlist[0].id,PricebookEntryId= pentrylist[0].Id,Quantity = 1,
                                     UnitPrice = 0.01,Product2id  = productlist[0].Id,Material_Recipient__c  = 'Account Manager');
        oitemlist.add(oi);
        
        oi = new OrderItem(OrderId= orderlist[1].id,PricebookEntryId= pentrylist[1].Id,Quantity = 1,
                           UnitPrice = 0.01,Product2id  = productlist[1].Id,Material_Recipient__c  = 'Account Manager');
        oitemlist.add(oi);
        oi = new OrderItem(OrderId= orderlist[1].id,PricebookEntryId= pentrylist[2].Id,Quantity = 1,
                           UnitPrice = 0.01,Product2id  = productlist[2].Id,Material_Recipient__c  = 'Account Manager');
        oitemlist.add(oi);
        oi = new OrderItem(OrderId= orderlist[1].id,PricebookEntryId= pentrylist[3].Id,Quantity = 1,
                           UnitPrice = 0.01,Product2id  = productlist[3].Id,Material_Recipient__c  = 'Account Manager');
        oitemlist.add(oi);
        
        insert oitemlist;
                
        list<contact> contactList = new List<contact>();
        for(integer i =0;i<2;i++)
        {
        contact con = new contact ();
        con.Firstname='TestContactFirst'+i;
        con.lastname='TestContactLast'+i;
        con.Email = 'con'+i+'@gmail.com';
        con.Original_Service_Date__c = system.today().addDays(3);
        con.Primary_Phone__c = 'Mobile Phone';
        con.MobilePhone = '752-781-0090';
        con.Do_Not_Contact__c = true;
        con.Do_Not_Contact_Reason__c = 'ARC Decision';
        con.AccountId = id_acc;
            contactList.add(con);
        }
        
        insert contactList;
        
        // insert promotions
        Promotion__c pro = new Promotion__c(name = '$10 Amazon.com Gift Card and Florida Giveaway 2023',Supplier__c = 'Drive',Start_Date__c = system.today(), End_Date__c = system.today().addDays(100));
        insert pro;
        
        // create OpportunityContactRole
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = id_opp;
        ocr.ContactId = contactList[0].id;
        ocr.Role = 'Publicity Materials Recipient';
        insert ocr;
        TriggerHandler.clearAllBypasses() ;
        
        Test.startTest();
        OpportunityTeamMember opptyTeamMember = new OpportunityTeamMember(OpportunityId=id_opp,TeamMemberRole ='Account Manager',UserId=UserInfo.getUserId());
        insert opptyTeamMember;
        
        OpportunityContactRole opptyContactRole = new OpportunityContactRole(Role = 'Whom to Meet',ContactId=contactList[1].id,OpportunityId=id_opp);
        insert opptyContactRole;
        
        Opportunity_Promotion__c oppPromotion = new Opportunity_Promotion__c(Blood_Drive_Opportunity__c = id_opp, Promotion__c = pro.Id,Delivery_ID__c = 'Drive');
        insert oppPromotion;
        
        List<Note> notes = new List<Note>();
        notes.add(new Note(ParentId=id_acc,Title='Account Notes'));
        notes.add(new Note(ParentId=id_opp,Title='Opportunity Notes'));
        notes.add(new Note(ParentId=id_site,Title='Site Notes'));
        insert notes;
        
        Account_Service_Role__c asr = new Account_Service_Role__c(Contact__c=contactList[1].id,Account__c=id_acc,Account_Service_Role__c='Blood Program Leader');
        TriggerHandler.bypass('skedDriveHandler');
        insert asr;
        TriggerHandler.clearBypass('skedDriveHandler');
        PublicityReportNewPortfoliosController reportController = new PublicityReportNewPortfoliosController();
       
        
        reportController.getDriveStartDate();
        reportController.setDriveStartDate(null);
        
        reportController.getDriveEndDate();
        reportController.setDriveEndDate(null);
        
        reportController.getorderApprovedDate1();
        reportController.setorderApprovedDate1(null);
        
        reportController.getorderApprovedDate2();
        reportController.setorderApprovedDate2(null);
        reportController.search();
        
        system.assertEquals('No Input Found', reportController.errorMsg);
        bsf_portfolio__c bsf= new bsf_portfolio__c(Portfolio_Type__c='Account Manager',Taxonomy_Type__c='Bio Recruitment CD');
        insert bsf;
        reportController.searchPortfolio=string.valueof(reportController.portfolioOptions[0]);
        reportController.search();
        
        reportController = new PublicityReportNewPortfoliosController();
        reportController.search();
        
        reportController.getDriveStartDate();
        reportController.setDriveStartDate(null);
        
       
        reportController.setDriveStartDate(null);
        reportController.setDriveEndDate(null);
        reportController.setorderApprovedDate1(System.today() -10);
        reportController.setorderApprovedDate2(System.today() +10);
        reportController.search();
        
        for(PublicityReportNewPortfoliosController.ReportDataWrapper wrapper:reportController.ReportDataWrapperList){
            wrapper.isSelected = true;
        }
             
        reportController.selectedRecords();
        reportController.ExportToExcel();
        reportController.ExportToCSV();
        reportController.clear();
        reportController.ExportToCSV();
        
        datetime dt = system.now();
        reportController.getUserLocalTime(dt);
        Test.stopTest();
    }
}