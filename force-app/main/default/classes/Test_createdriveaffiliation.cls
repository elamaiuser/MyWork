@isTest
public class Test_createdriveaffiliation {
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> opprecordTypeMap  = new Map<String,Id>();
    public static Map<String,Id> siterecordTypeMap  = new Map<String,Id>();
    
    @isTest static void Mymethod(){
        /*
        recordTypeMap = recordTypeMap('Account');
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        
        List<Account> mobileAccList = new List<Account>();
        Account accobj;        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';        
        mobileAccList.add(accobj);
        insert mobileAccList;
        
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
        conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conlist.add(conObj);
        insert conlist;
        
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';        
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
        insert skedlocationlist;
        
        recordTypeMap = recordTypeMap('Opportunity');
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = mobileAccList[0].Id;
        optyObj.Drive_Site__c = skedlocationlist[0].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.Type_of_Drive__c = 'Mobile';
        optyObj.Is_Template__c = true;
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
        
        Opportunity opp=new Opportunity();        
        opp.AccountId=mobileAccList[0].Id;
        opp.From_Template_Id__c=opplist[0].Id;
        opp.Drive_Site__c = skedlocationlist[0].Id;
        opp.Name = 'Test Drive First';
        opp.StageName='Discovery';
        opp.Drive_Date__c = System.today().addDays(57);
        opp.Type_of_Drive__c = 'Mobile';
        opp.CloseDate = System.today();
        opp.Start_Time__c = System.now().Time();
        opp.End_Time__c = System.now().Time()+1;
        opp.Anticipated_Registered_Donors__c = 1;
        opp.X2RBC_Projected_Procedures__c = 1;
        opp.WB_Projected_Procedures__c = 2;
        opp.Plasma_Pheresis_Projected_Procedures__c = 3;
        opp.Platelet_Projected_Procedures__c = 1;
        opp.Open_to_Public__c='Yes';
        insert opp;
        
        List<Marketing_program__c> mar=new List<Marketing_program__c>();
        Marketing_program__c mp=new Marketing_program__c();
        mp.name='abc';
        mp.External_Name__c='abctest';
        mp.Scope__c='Drive';
        mar.add(mp); 
        insert mar;
        
        List<Drive_Marketing_Programs__c> newDriveAffiliations = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c newDriveAff = new Drive_Marketing_Programs__c();
        newDriveAff.Migration_ID__c =null;//empty migration id
        newDriveAff.Blood_Drive_Opportunity__c = opplist[0].id;
        newDriveAff.Account__c = mobileAccList[0].Id;
        newDriveAff.Marketing_Program__c=mar[0].id;
        newDriveAffiliations.add(newDriveAff);
        insert newDriveAffiliations;
        
        Set<ID> templateIdSet = new Set<Id>(); 
        Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>(); 
     
        templateIdSet.add(opplist[0].id);
        newOppMap.put(opp.id,opp);
     
        Test.startTest();
        Database.executeBatch(new CreateDriveAffiliationsBatch (templateIdSet ,newOppMap ));
        Test.stopTest();
     */   
    }
    //Method to get the map of recordType Name as key and recordTypeId as value for account records
    /*public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }*/
}