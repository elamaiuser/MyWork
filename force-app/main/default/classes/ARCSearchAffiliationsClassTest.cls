/*
* This Test class covering the following Classes
* ARCSearchAffiliationsClass, 
* */
@isTest
public class ARCSearchAffiliationsClassTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String driveDesignationRecType = 'Drive Designation';
    public static String marketingProgramRecType = 'Marketing Program';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>(); 
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMapHelper( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        
        // Create Account
        List<Account> mobileAccList = new List<Account>();        
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';
		accobj.Internal_Name__c='Exavalu';     
        mobileAccList.add(accobj);
        
        TriggerHandler.bypass('AccountTriggerHandler');
        insert mobileAccList;
        TriggerHandler.clearBypass('AccountTriggerHandler');
        List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
        
        BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
        Portland_OR_AM_01.Name='Wisconsin Region';
        Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
        Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Type__c='RDSE';
        Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
        Portland_OR_AM_01.Territory_Portfolio__c=false;			
        bsfPortf.add(Portland_OR_AM_01);
            
            
            
        BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
        Sickle_Cell_AM_04.Name='Test DRD Territory';
        Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
        Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
        Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
        Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
        Sickle_Cell_AM_04.Portfolio_Type__c='Account Manager';
        Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
        Sickle_Cell_AM_04.Territory_Portfolio__c=false;
        bsfPortf.add(Sickle_Cell_AM_04);
        
        BSF_Portfolio__c Sickle_Cell_AM_05 = new BSF_Portfolio__c();
        Sickle_Cell_AM_05.Name='Test District 1';
        Sickle_Cell_AM_05.Account_Based_Portfolio__c=true;
        Sickle_Cell_AM_05.External_Key__c='Sickle Cell_53E_SAM05';
        Sickle_Cell_AM_05.Portfolio_Code__c='SAM05';
        Sickle_Cell_AM_05.Portfolio_Name__c='Sickle Cell AM 05';
        Sickle_Cell_AM_05.Portfolio_Type__c='District Manager';
        Sickle_Cell_AM_05.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
        Sickle_Cell_AM_05.Territory_Portfolio__c=false;
        bsfPortf.add(Sickle_Cell_AM_05);
        
        insert bsfPortf;
        // Create Collection Region
        Collections_Region__c clRegion;
        clRegion = new Collections_Region__c();
        clRegion.Name = 'Wisconsin Region';
        clRegion.Region_Code__c = '32E';
        insert clRegion;
        
        // create DRD Teritorry
        DRD_Territory__c dTeritory = new DRD_Territory__c();
        dTeritory.Name = 'Test DRD Territory';
        insert dTeritory;
        
        // create District
        District__c dst = new District__c() ;
        dst.Name = 'Test District 1';
        insert dst;
        
        // create Collection Teritorry
        Collections_Territory__c clTeritory;
        clTeritory = new Collections_Territory__c();
        clTeritory.Name = 'Dale, WI 54931';
        clTeritory.Zip__c = mobileAccList[0].BillingPostalCode ;
        clTeritory.Region__c = clRegion.Id ;
        clTeritory.DRD_Territory2__c = dTeritory.Id ;
        clTeritory.District__c = dst.Id ;
        insert clTeritory;
        
        // Create Affiliation
        List<Marketing_Program__c> affiliationList = new List<Marketing_Program__c>();
        Marketing_Program__c affiliationobj;     
        recordTypeMap = recordTypeMapHelper( 'Marketing_Program__c' );
        recTypeId = recordTypeMap.get(driveDesignationRecType); 
        
        // Nation wide Marketing Program == Yes and Scope  == Account
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_1';
        affiliationobj.External_Name__c = 'RSMO_1';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'N/A';
        affiliationobj.RecordTypeId = recTypeId ;
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Drive
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_2';
        affiliationobj.External_Name__c = 'RSMO_2';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'Mobile';
        affiliationobj.RecordTypeId = recTypeId ;
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Both
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_3';
        affiliationobj.External_Name__c = 'RSMO_3';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = '';
        affiliationobj.RecordTypeId = recTypeId ;
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Template
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_4';
        affiliationobj.External_Name__c = 'RSMO_4';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = '';
        affiliationobj.RecordTypeId = recTypeId ;
        affiliationList.add(affiliationobj);
        
        
        // Nation wide Marketing Program == No and Scope  == Account
        recTypeId = recordTypeMap.get(marketingProgramRecType); 
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_5';
        affiliationobj.External_Name__c = 'RSMO_5';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'No';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'N/A';
        affiliationobj.RecordTypeId = recTypeId ;
        affiliationList.add(affiliationobj);
        
        insert affiliationList;
        
        
        // create child Affiliation: Marketing_Program_Region__c
        Marketing_Program_Region__c mpRegion;
        mpRegion = new Marketing_Program_Region__c();
        mpRegion.Donor_Services_Region__c = clRegion.Id ;
        mpRegion.Marketing_Program__c = affiliationList[4].Id ;
        mpRegion.BSF_Portfolio_Region__c = Portland_OR_AM_01.Id;
        insert mpRegion ;
            
        // create child Affiliation: Marketing_Program_Territory__c
        Marketing_Program_Territory__c mpTeritorry;
        mpTeritorry = new Marketing_Program_Territory__c();
        mpTeritorry.BSF_Portfolio_Territory__c = Sickle_Cell_AM_04.Id ;
        mpTeritorry.DRD_Territory__c=dTeritory.id;
        mpTeritorry.Marketing_Program__c = affiliationList[4].Id ;
        insert mpTeritorry;
        
        // create child Affiliation: Marketing_Program_District__c
        Marketing_Program_District__c mpDistrict;
        mpDistrict = new Marketing_Program_District__c();
        mpDistrict.BSF_Portfolio_District__c = Sickle_Cell_AM_05.Id ;
        mpDistrict.District__c=dst.id;
        mpDistrict.Marketing_Program__c = affiliationList[4].Id ;
        insert mpDistrict; 
        
        
        recordTypeMap = recordTypeMapHelper( 'sked__Location__c' );
        recTypeId = recordTypeMap.get('Mobile Site');
        
        // create Tag
        sked__Tag__c tag = new sked__Tag__c(Name = 'Inside', sked__Type__c = 'Physical Location Type', sked__Classification__c = 'Global');
        insert tag;
        
        // create Site Location
        /*sked__Location__c site = new sked__Location__c(RecordTypeId = recTypeId, sked_Zip_Code__c = '67854', sked_Pay_for_Parking_Details__c = 'test pay for parking', 
                                                       sked_Physical_Location_Type__c = 'Inside', sked_Floor_Description__c = 'Floor - 100', 
                                                       sked_Room_Name__c = 'Room 100', sked_National_Name__c = 'TestSite', 
                                                       sked_Automation_Suitability__c = 'Unsuitable', sked_Site_Main_Phone__c = '987-654-3210', 
                                                       sked_Site_Building_Name__c = 'test 100',
                                                       sked_Wireless_Policy__c = 'Accepted',
                                                       Source__c ='Custom New Form');
        insert site;*/
        
        sked__Location__c site = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  recTypeId,  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
        );
        insert site;
        
        recordTypeMap = recordTypeMapHelper( 'Opportunity' );
        recTypeId = recordTypeMap.get('Mobile Opp');
        
        // Create Opportunity
        Opportunity mobileOpportunityRecord = new Opportunity(Name='Test opp', RecordTypeId = recTypeId, AccountId = mobileAccList[0].Id, Drive_Date__c = Date.today().addDays(7), 
                                                              is_template__c = false, StageName = 'Discovery', CloseDate = Date.today().addDays(6), 
                                                              Procedure_Projections_Template__c = 10,End_Time__c=Time.newInstance(18, 30, 2, 20));
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert mobileOpportunityRecord;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        // create Temlate type Opportunity
        Opportunity TemplateOpportunityRecord = new Opportunity(Name='Test Template opp', RecordTypeId = recTypeId, AccountId = mobileAccList[0].Id, Drive_Date__c = Date.today().addDays(7), 
                                                                is_template__c = true, StageName = 'Discovery', CloseDate = Date.today().addDays(6), 
                                                                Procedure_Projections_Template__c = 10,End_Time__c=Time.newInstance(18, 30, 2, 20));
        insert TemplateOpportunityRecord;
        
        
    }
    
    @isTest static void getAffiliationTypes() {
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
        
        System.runAs( AdminUser ){
            
            // Account
            List<Account> testAccountDataList = [ Select Id, BillingPostalCode from Account where Name = 'Exavalu' and BillingPostalCode = '30622' limit 1 ];
            ARCSearchAffiliationsClass.getAffiliationTypes(testAccountDataList[0].Id, false );
            
            
            
            // Template type Opportunity
            List<Opportunity> templateOppList = [ Select Id from Opportunity where is_template__c = true limit 1 ];
            ARCSearchAffiliationsClass.getAffiliationTypes(templateOppList[0].Id, true );
            
            // Opportunity
            List<Opportunity> oppList = [ Select Id from Opportunity where is_template__c = false limit 1 ];
            System.debug( 'oppList is ' + oppList );
            ARCSearchAffiliationsClass.getAffiliationTypes(oppList[0].Id, false );
            
            // Get List Of Affiliation for Account
            List<ARCSearchAffiliationsClass.Affiliationwrapper> aflwraper = ARCSearchAffiliationsClass.getAffiliations( recordTypeMap.get(driveDesignationRecType), testAccountDataList[0].BillingPostalCode, testAccountDataList[0].Id, false);
            List<ARCSearchAffiliationsClass.Affiliationwrapper> aflwraperDrive = ARCSearchAffiliationsClass.getAffiliations( recordTypeMap.get(driveDesignationRecType), testAccountDataList[0].BillingPostalCode, oppList[0].Id, false);
            
            //System.assertEquals( 3, aflwraper.size() );
            // Opportunity
            oppList = [ Select Id from Opportunity where is_template__c = false limit 1 ];
            System.debug( 'oppList is ' + oppList );
            ARCSearchAffiliationsClass.getAffiliationTypes(oppList[0].Id, false );
            
            List<Id> mpList = new List<Id>();
            List<sObject> sObjList = new List<sObject>();
            for(Marketing_Program__c mp:[Select Id,Nationwide_Marketing_Program__c from Marketing_Program__c]){
                mpList.add(mp.Id);
                sObjList.add(mp);
            }
            
            ARCSearchAffiliationsClass.getDonorServiceDivision(mpList,new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Wisconsin Region'].Id});
            ARCSearchAffiliationsClass.getDRDTeritorry(mpList,new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Test DRD Territory'].Id});
            ARCSearchAffiliationsClass.getDistrict(mpList,new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Test District 1'].Id});
            ARCSearchAffiliationsClass.getFilteredAffiliationList(sObjList,'TRUE');
            ARCSearchAffiliationsClass.getNationalAffiliationList(recordTypeMapHelper('Marketing_Program__c').get(driveDesignationRecType));
        }
        
    }
    //Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMapHelper(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    } 
}