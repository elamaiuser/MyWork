/*
 * This Test class covering the following Classes
 * OrderTrigger 
 * */
@isTest
public class OrderTrigger_Test {

    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();

    
    @isTest static void orderMethod1() {
        
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
        System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        //atm.Is_Covering_Recruiter__c = true;
        //atm.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm);
        insert atmList;
        
        
        // To Create opportunity multiple data setup requited, location object
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
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
        conlist.add(conObj);
        insert conlist;
            
        // insert sked tag  
        sked__Tag__c skedTag = new sked__Tag__c();
        skedTag.Name = 'Outside';
        skedTag.sked__Type__c = 'Physical Location Type';
        insert skedTag; 
            
            // sked_Date_Site_Inspection_Completed__c
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
        siteObj.source__c='Custom New Form';
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
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Opportunity optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        
        opplist.add(optyObj);       
        insert opplist;
        
        test.startTest();
        //This is added to cover 1084 AccountTeamMemberService methods--Starts
        AccountTeamMember atm2 = new AccountTeammember();
        atm2.AccountAccessLevel = 'Edit';
        atm2.CaseAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.userId = DRDAMUser.Id ;
        atm2.AccountId = mobileAccList[0].Id;
        atm2.TeamMemberRole = 'District Manager';
        atm2.Start_Date__c = System.today();
        atm2.End_Date__c = System.today();
        atm2.Is_Covering_Recruiter__c = true;
        atm2.Coverage_Reason__c = 'Vacant Territory';
        atmList.add(atm2);
        
        AccountTeamMember atm3 = new AccountTeammember();
        atm3.AccountAccessLevel = 'Edit';
        atm3.CaseAccessLevel = 'Edit';
        atm3.OpportunityAccessLevel = 'Edit';
        atm3.userId = AdminUser.Id ;
        atm3.AccountId = mobileAccList[0].Id;
        atm3.TeamMemberRole = 'Account Manager';
        atm3.Start_Date__c = System.today();
        atm3.End_Date__c = System.today();
        atm3.Is_Covering_Recruiter__c = true;
        atm3.Coverage_Reason__c = 'Leave of Absence (LOA)';
        //atmList.add(atm3);
        
        
        insert atmList;
        
        
        AccountTeamMemberService.populateDefaultAllocationFiledsOnInsert(atmList);
        
        List<AccountTeamMember> atmListToUpdate = [SELECT Id,AccountAccessLevel,CaseAccessLevel,OpportunityAccessLevel,userId,AccountId,TeamMemberRole,Start_Date__c,End_Date__c FROM AccountTeamMember WHERE AccountId =:mobileAccList[0].Id];
        AccountTeamMember atmToUpdate1= atmListToUpdate[0];
        atmToUpdate1.TeamMemberRole = 'Recruiter';
        
        update atmToUpdate1;
        Delete atmToUpdate1;
        
                
        UpdateAccountTeamMemberDailyBatch batch2 = new UpdateAccountTeamMemberDailyBatch();
        Database.executeBatch(batch2);
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        System.runAs( DRDAMUser){
            
            // create order 
            List<Order> orderlist = new List<Order>();
            Order o = new Order();
            o.name='Test1';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Same';
            o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test2';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            //o.Material_Recipient_Type__c = 'Same';
            //o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test3';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            // in case of split only
            o = new Order();
            o.name='Test4';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test5';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            try{
                insert orderlist;
                List<Order> odr = [select id , BudgetCurrency__c from Order];
                System.assertEquals( 0.688, odr[0].BudgetCurrency__c ); 
            }catch(Exception e ){
                //String errormsg = e.getMessage();
                //System.assert( errormsg.contains('Selected Material Recipient not matched as in Order, ether select exact value as in Order or left it blank') );
            }
        } 
        test.stopTest();    
    }

    @isTest static void orderMethod2() {
        
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
        System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atmList.add(atm);
        insert atmList;
        
        
        // To Create opportunity multiple data setup requited, location object
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact1@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0091';
        conlist.add(conObj);
        insert conlist;
            
        // insert sked tag  
        sked__Tag__c skedTag = new sked__Tag__c();
        skedTag.Name = 'Outside';
        skedTag.sked__Type__c = 'Physical Location Type';
        insert skedTag; 
            
            // sked_Date_Site_Inspection_Completed__c
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
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.sked_Address_1__c = 'Test Address'; 
        siteObj.sked_City__c = 'city'; 
        siteObj.sked_County__c = 'United States'; 
        siteObj.sked_State__c = 'Texas'; 
        siteObj.sked_Zip_Code__c = '27560';
        siteObj.Source__c ='Custom New Form';
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
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        
        opplist.add(optyObj);       
        insert opplist;
        
        // Create Marketing Program/Affiliation
        List<Marketing_Program__c> mps = new List<Marketing_Program__c>();
        Marketing_Program__c mp ;
        mp = new Marketing_Program__c();
        mp.Name = 'Pint Sized Hero';
        mp.External_Name__c = 'Pint Sized Hero';
        mp.Scope__c = 'Drive';
        mp.Drive_Type__c = 'Mobile';
        mps.add(mp);
        
        mp = new Marketing_Program__c();
        mp.Name = 'Future Blood Donor';
        mp.External_Name__c = 'Future Blood Donor';
        mp.Scope__c = 'Drive';
        mp.Drive_Type__c = 'Mobile';
        mps.add(mp);        
        
        insert mps;
        
        // Crreate Drive Marketing Program/Affiliation        
        List<Drive_Marketing_Programs__c> dmps = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c dmp;
        
        dmp = new Drive_Marketing_Programs__c();
        dmp.Blood_Drive_Opportunity__c = opplist[0].Id;
        dmp.Marketing_Program__c = mps[0].Id;
        dmps.add(dmp);
        
        dmp = new Drive_Marketing_Programs__c();
        dmp.Blood_Drive_Opportunity__c = opplist[0].Id;
        dmp.Marketing_Program__c = mps[1].Id;
        dmps.add(dmp);
        
        insert dmps;
        
        /*
        // create product and pricebook
        List<Product2> productlist = new List<Product2>(); 
        Product2 prod = new Product2(Name = 'Laptop X200',
                                    
                                     Family = 'Hardware');
        productlist.add(prod);
        insert productlist;
       
        Id pricebookId = Test.getStandardPricebookId();
       
        // create Pricebook entry
        List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
                                                            Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,
                                                            UnitPrice = 0.01, IsActive = true);
                                                            
                                                            
        pentrylist.add(standardPrice);
        
        insert pentrylist;
        
        */
        
        Id pricebookId = Test.getStandardPricebookId();
        
        System.runAs( DRDAMUser){
            test.startTest();
            // create order 
            List<Order> orderlist = new List<Order>();
            Order o = new Order();
            o.name='Test1';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Same';
            o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test2';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            //o.Material_Recipient_Type__c = 'Same';
            //o.Material_Recipient__c = 'Account Manager';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test3';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            // in case of split only
            o = new Order();
            o.name='Test4';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test5';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            orderlist.add(o);
            
            
            
            
            //insert orderlist;

            /*
            List<OrderItem> oitemlist = new List<OrderItem>();
            OrderItem oi = new OrderItem();
            oi.OrderId= orderlist[0].id ;
            oi.PricebookEntryId= pentrylist[0].Id ;
            oi.Quantity = 1 ;
            oi.UnitPrice = 0.01 ; 
            oi.Product2id  = productlist[0].Id ;
            oi.Material_Recipient__c  = 'Staging Office';
            oitemlist.add(oi);
            
            oi = new OrderItem();
            oi.OrderId= orderlist[1].id ;
            oi.PricebookEntryId= pentrylist[0].Id ;
            oi.Quantity = 1 ;
            oi.UnitPrice = 0.01 ; 
            oi.Product2id  = productlist[0].Id ;
            oi.Material_Recipient__c  = 'Account Manager';
            oitemlist.add(oi);
            
            oi = new OrderItem();
            oi.OrderId= orderlist[2].id ;
            oi.PricebookEntryId= pentrylist[0].Id ;
            oi.Quantity = 1 ;
            oi.UnitPrice = 0.01 ; 
            oi.Product2id  = productlist[0].Id ;
            oi.Material_Recipient__c  = 'Staging Office';
            oitemlist.add(oi);          
            */
            try{
                insert orderlist;
                
                List<Order> odr = [select id , BudgetCurrency__c from Order];
                //System.assertEquals( 1.040, odr[0].BudgetCurrency__c ); 
                
            }catch(Exception e ){
                //String errormsg = e.getMessage();
                //System.assert( errormsg.contains('Selected Material Recipient not matched as in Order, ether select exact value as in Order or left it blank') );
            }

            test.stopTest();    
            
        }       
    }   
    
    
    @isTest static void orderMethod3() {
        
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
        System.debug( 'recTypeId is ' + recTypeId );
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';     
        accobj.Type = 'Education';        
        accobj.Industry_Code__c = 'High School';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        // insert Account Team and add DRDAMUser
        List<AccountTeammember> atmList = new List<AccountTeammember>();
        AccountTeammember atm;
        atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = mobileAccList[0].Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = System.today();
        atm.End_Date__c = System.today().addDays(3);
        atmList.add(atm);
        insert atmList;
        
        
        // To Create opportunity multiple data setup requited, location object
        
        // create Contact
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact2@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0092';
        conlist.add(conObj);
        insert conlist;
            
        // insert sked tag  
        sked__Tag__c skedTag = new sked__Tag__c();
        skedTag.Name = 'Outside';
        skedTag.sked__Type__c = 'Physical Location Type';
        insert skedTag; 
            
            // sked_Date_Site_Inspection_Completed__c
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
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.sked_Address_1__c = 'Test Address'; 
        siteObj.sked_City__c = 'city'; 
        siteObj.sked_County__c = 'United States'; 
        siteObj.sked_State__c = 'Texas'; 
        siteObj.sked_Zip_Code__c = '27560';
        siteObj.Source__c ='Custom New Form';
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
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.Anticipated_Registered_Donors__c = 1;   
        // fields to calculate Total Products projected
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.WB_Projected_Procedures__c = 2;
        optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
        optyObj.Platelet_Projected_Procedures__c = 1;
        
        opplist.add(optyObj);       
        insert opplist;
        
        // Create Marketing Program/Affiliation
        List<Marketing_Program__c> mps = new List<Marketing_Program__c>();
        Marketing_Program__c mp ;
        mp = new Marketing_Program__c();
        mp.Name = 'Pint Sized Hero1';
        mp.External_Name__c = 'Pint Sized Hero1';
        mp.Scope__c = 'Drive';
        mp.Drive_Type__c = 'Mobile';
        mps.add(mp);
        
        mp = new Marketing_Program__c();
        mp.Name = 'Future Blood Donor1';
        mp.External_Name__c = 'Future Blood Donor1';
        mp.Scope__c = 'Drive';
        mp.Drive_Type__c = 'Mobile';
        mps.add(mp);        
        
        insert mps;
        
        // Crreate Drive Marketing Program/Affiliation        
        List<Drive_Marketing_Programs__c> dmps = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c dmp;
        
        dmp = new Drive_Marketing_Programs__c();
        dmp.Blood_Drive_Opportunity__c = opplist[0].Id;
        dmp.Marketing_Program__c = mps[0].Id;
        dmps.add(dmp);
        
        dmp = new Drive_Marketing_Programs__c();
        dmp.Blood_Drive_Opportunity__c = opplist[0].Id;
        dmp.Marketing_Program__c = mps[1].Id;
        dmps.add(dmp);
        
        insert dmps;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        
        // create product and pricebook
        List<Product2> productlist = new List<Product2>(); 
        Product2 prod = new Product2(Name = 'Laptop X200',
                                    
                                     Family = 'Hardware');
        productlist.add(prod);
        insert productlist;
       
        //Id pricebookId = Test.getStandardPricebookId();
       
        // create Pricebook entry
        List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
                                                            Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,
                                                            UnitPrice = 0.01, IsActive = true);
                                                            
                                                            
        pentrylist.add(standardPrice);
        
        insert pentrylist;
        
        
        
        System.runAs( DRDAMUser){
            test.startTest();
            // create order 
            List<Order> orderlist = new List<Order>();
            Order o = new Order();
            o.name='Test1';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            o.Publicity_Approved__c = false;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test2';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            o.Publicity_Approved__c = false;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test3';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            o.Publicity_Approved__c = false;
            orderlist.add(o);
            
            // in case of split only
            o = new Order();
            o.name='Test4';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            o.Publicity_Approved__c = false;
            orderlist.add(o);
            
            o = new Order();
            o.name='Test5';
            o.AccountId= mobileAccList[0].Id ;
            o.OpportunityId = opplist[0].Id ;
            o.Material_Recipient_Type__c = 'Split';
            o.Material_Recipient__c = 'Account Manager;Account Contact';
            o.EffectiveDate=system.today();
            o.status='draft' ;
            o.Pricebook2Id =  pricebookId ;
            o.Publicity_Approved__c = false;
            orderlist.add(o);
            
            try{
                insert orderlist;
                
                
                List<OrderItem> oitemlist = new List<OrderItem>();
                OrderItem oi = new OrderItem();
                oi.OrderId= orderlist[0].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oi.Material_Recipient__c  = 'Account Manager';
                oitemlist.add(oi);
                
                oi = new OrderItem();
                oi.OrderId= orderlist[1].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oi.Material_Recipient__c  = 'Account Manager';
                oitemlist.add(oi);
                
                oi = new OrderItem();
                oi.OrderId= orderlist[2].id ;
                oi.PricebookEntryId= pentrylist[0].Id ;
                oi.Quantity = 1 ;
                oi.UnitPrice = 0.01 ; 
                oi.Product2id  = productlist[0].Id ;
                oi.Material_Recipient__c  = 'Account Contact';
                oitemlist.add(oi);          
            
                insert oitemlist;
                
                for( Order ot : orderlist){
                    ot.Publicity_Approved__c = true;
                }
                update orderlist;
                List<Order> odr = [select id , BudgetCurrency__c from Order];
                //System.assertEquals( 1.160, odr[0].BudgetCurrency__c ); 
            }catch(Exception e ){
                String errormsg = e.getMessage();
            }

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