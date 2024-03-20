@isTest
private class OpportunityTeamMemberTriggerTest {
    @testSetup 
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
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
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
            LocaleSidKey = 'en_US',
            UserRoleId = urole.Id
        );

        User DRDAProfile = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last',
            Email = 'DRDManager000@amamama.com',
            Username = 'drdusm000@amamama.com' + System.currentTimeMillis(),
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
            insert DRDAProfile;
        }
        System.runAs( AdminUser ){
            List<Account> mobileAccList = new List<Account>();
            
            Account accObj;
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';            
            mobileAccList.add(accobj); 
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu2';
            accObj.BillingPostalCode = '30623';            
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
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = AdminUser.Id ;
            atm.AccountId = mobileAccList[1].Id ;
            atm.TeamMemberRole = 'Recruiter';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            insert atmList;
            
            
            
            
            Contact conObj = new Contact();
            conObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
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
            
            BSF_Portfolio__c Greater_Alleghenies_DRA_01 = new BSF_Portfolio__c();
            Greater_Alleghenies_DRA_01.Name='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Account_Based_Portfolio__c = true;
            Greater_Alleghenies_DRA_01.External_Key__c='Booking Support_BD32_27E_Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Code__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Name__c='Greater Alleghenies DRA 01';
            Greater_Alleghenies_DRA_01.Portfolio_Type__c=BSF_Constants.Booking_Support;
            Greater_Alleghenies_DRA_01.Taxonomy_Type__c='Bio Booking Support';
            Greater_Alleghenies_DRA_01.Territory_Portfolio__c= false;
            bsfPortf.add(Greater_Alleghenies_DRA_01);
            
            BSF_Portfolio__c American_Red_Cross = new BSF_Portfolio__c();
            American_Red_Cross.Name='American Red Cross';
            American_Red_Cross.Account_Based_Portfolio__c=true;
            American_Red_Cross.External_Key__c='National Account_1';
            American_Red_Cross.Portfolio_Code__c='1';
            American_Red_Cross.Portfolio_Name__c='American Red Cross';
            American_Red_Cross.Portfolio_Type__c='National Account Manager';
            American_Red_Cross.Taxonomy_Type__c='National Account Manager Portfolio';
            American_Red_Cross.Territory_Portfolio__c=false;
            bsfPortf.add(American_Red_Cross);
            
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
            
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = time.newInstance(09, 30, 0, 0);
            optyObj.End_Time__c = time.newInstance(10, 30, 0, 0);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );
            
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'Exavalu2'].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive2';
            optyObj.StageName = 'Discovery';
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c = time.newInstance(09, 30, 0, 0);
            optyObj.End_Time__c = time.newInstance(10, 30, 0, 0);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj );          
            
            insert oppsobjlist;
        }        
        
    }
    @isTest
    private static void testTrigger1(){
        User usr = [SELECT Id FROM USER WHERE Email = 'DRDProfile000@amamama.com' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
            OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.OpportunityAccessLevel = 'Edit';
            otm.userId = usr.Id;
            otm.OpportunityId = opp.Id;
            otm.TeamMemberRole = 'Account Manager';
            otm.Start_Date__c = System.today();
            insert otm;
        Test.stopTest();
    }
    @isTest
    private static void testTrigger2(){
        List<String> emlist = new List<String>{'DRDProfile000@amamama.com','DRDManager000@amamama.com'};
        List<User> usrlist = [SELECT Id FROM USER WHERE Email IN:emlist LIMIT 2];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityAccessLevel = 'Edit';
        otm.userId = usrlist[0].Id;
        otm.OpportunityId = opp.Id;
        otm.TeamMemberRole = 'Account Manager';
        otm.Start_Date__c = System.today();
        otmList.add(otm);
        OpportunityTeamMember otm1 = new OpportunityTeamMember();
        otm1.OpportunityAccessLevel = 'Read';
        otm1.userId = usrlist[1].Id;
        otm1.OpportunityId = opp.Id;
        otm1.TeamMemberRole = 'Sales Manager';
        otm1.Start_Date__c = System.today();
        otmList.add(otm1);
        insert otmList;
        Test.startTest();
            try{
                OpportunityTeamMember otm2 = [SELECT Id FROM OpportunityTeamMember WHERE TeamMemberRole = 'Sales Manager' LIMIT 1];
                delete otm2;
            }catch(Exception exp){}
        Test.stopTest();
    }
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
}