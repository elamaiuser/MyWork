@isTest(SeeAllData = false)
private class UpdateOpportunityStageBatchTest {
    static String Id_CollectionOperation = '';

    @testSetup
    static void Setup() {
        // Create test data - insert test Opportunities as needed
        Account accobj;        
        accobj = new Account();
       // accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30146';
        accobj.Internal_Name__c = 'Exavalu';       
        //AccList.add(accobj);
        insert accobj;
        
        Contact conObj = new Contact();
        conObj.AccountId = accobj.Id ;
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
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        insert conObj;
        
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        //siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conObj.Id;
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
        siteObj.operation_type__c = 'Integrated';
        triggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;
        
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = accobj.Id;
        opp1.Drive_Site__c = siteObj.Id;
        opp1.Name = 'Test Drive 1';
        opp1.StageName = 'Discovery';
        opp1.Drive_Date__c = System.today();
        opp1.Type_of_Drive__c = 'Mobile';
        opp1.CloseDate = System.today();
        opp1.Start_Time__c = System.now().Time();
        opp1.End_Time__c = System.now().Time()+1;
        opp1.Anticipated_Registered_Donors__c = 10;   
        opp1.Plasma_Pheresis_Projected_Procedures__c = 10;
        opp1.Platelet_Projected_Procedures__c = 11;   
        opp1.Number_of_Platelet_Assets__c = 10;
        opp1.Number_of_Plasma_Assets__c = 10;
        opp1.Number_of_2RBC_Assets__c = 10;
        opp1.Calendar_Description__c = 'Push -35';
        opp1.Online_Donor_Message__c = 'demo';
        opp1.Platelet_Pheresis_Procedures__c = 10;
        opp1.Plasma_Pheresis_Procedures__c = 10;
        opp1.WB_Projected_Procedures__c = 10;
        opp1.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp1.X2RBC_Projected_Procedures__c = 10;
        opp1.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        //opp1.sked_Cancellation_Reason__c = 'Staff Shortage';
        //opp1.Initiated_By__c = 'ARC_Initiated_Mobile';
        opp1.Is_Template__c = false;
        opp1.Processing_Status__c = 'Mass Update Not Processed';
        //opplist.add(opp1);  
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert opp1;
        
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
            insert testCollectionOperation1;
        
    }
    
    static testmethod void testmethod1()
    {
        
        Account accobj = [Select Id, Name, BillingPostalCode, Internal_Name__c From Account LIMIT 1];
        
        Contact conObj = [Select Id, AccountId, FirstName, LastName From Contact LIMIT 1];
        
        sked__Location__c siteObj = [Select Id, Name, sked__Address__c, sked_Date_Site_Inspection_Completed__c, sked_Zip_Code__c From sked__Location__c Limit 1];
        
        Opportunity opp1 = [Select Id, AccountId, Drive_Site__c, Name, StageName, Is_Template__c, DriveStatus__c From Opportunity LIMIT 1];
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = [Select Id, Name From Biomed_Collection_Op_Center__c LIMIT 1];
                 
		Id_CollectionOperation = testCollectionOperation1.Id;
        
        //List<sked_Drive__c> DOC = new List<sked_Drive__c>();
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive 1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = siteObj.id,
                                                        sked_Opportunity__c = opp1.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = accobj.id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = 'Draft');
        
        triggerHandler.bypass('OpportunityTriggerHandler');
       
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        insert testDrive1;
        
        
        
        //List<sked_Drive__c> docCreatedList = [select id from sked_drive__c where sked_Opportunity__c in :opp1.id];
        
             testDrive1.sked_status__c = 'Tentative';
             //oppIds.add(doc.sked_Opportunity__c);
         
        update testDrive1;
        //sked_Drive__c driveAfterUpdate = [select id, sked_status__c,sked_opportunity__c from sked_drive__C where id =:testDrive1.Id limit 1];
        //system.debug('driveAfterUpdate '+driveAfterUpdate.sked_status__c);
        List<Opportunity> oppListNew = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        system.debug('oppListNew '+oppListNew);
        for(Opportunity opp : oppListnew)
        {
            system.debug('opp.drive status '+opp.DriveStatus__c);
        }
        Test.startTest();
        UpdateOpportunityStageBatch batchClassInstanceWithMap = new UpdateOpportunityStageBatch(oppListNew);
        Database.executeBatch(batchClassInstanceWithMap);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        List<Opportunity> oppListNewAssert = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        
        Assert.areEqual('Discovery', oppListNew[0].StageName, 'StageName should be updated to "Discovery"');
		Assert.areEqual('Committed', oppListNewAssert[0].StageName, 'StageName should be updated to "Committed"');
               
    }
    
    static testmethod void testmethod2()
    {
        Account accobj = [Select Id, Name, BillingPostalCode, Internal_Name__c From Account LIMIT 1];
        
        Contact conObj = [Select Id, AccountId, FirstName, LastName From Contact LIMIT 1];
        
        sked__Location__c siteObj = [Select Id, Name, sked__Address__c, sked_Date_Site_Inspection_Completed__c, sked_Zip_Code__c From sked__Location__c Limit 1];
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = accobj.Id;
        opp1.Drive_Site__c = siteObj.Id;
        opp1.Name = 'Test Drive 2';
        opp1.StageName = 'Discovery';
        opp1.Drive_Date__c = System.today().addDays(+56);
        opp1.Type_of_Drive__c = 'Mobile';
        opp1.CloseDate = System.today();
        opp1.Start_Time__c = System.now().Time();
        opp1.End_Time__c = System.now().Time()+1;
        opp1.Anticipated_Registered_Donors__c = 10;   
        opp1.Plasma_Pheresis_Projected_Procedures__c = 10;
        opp1.Platelet_Projected_Procedures__c = 11;   
        opp1.Number_of_Platelet_Assets__c = 10;
        opp1.Number_of_Plasma_Assets__c = 10;
        opp1.Number_of_2RBC_Assets__c = 10;
        opp1.Calendar_Description__c = 'Push -35';
        opp1.Online_Donor_Message__c = 'demo';
        opp1.Platelet_Pheresis_Procedures__c = 10;
        opp1.Plasma_Pheresis_Procedures__c = 10;
        opp1.WB_Projected_Procedures__c = 10;
        opp1.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp1.X2RBC_Projected_Procedures__c = 10;
        opp1.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        opp1.sked_Cancellation_Reason__c = 'Staff Shortage';
        opp1.Initiated_By__c = 'ARC_Initiated_Mobile';
        opp1.Is_Template__c = false;
        opp1.Processing_Status__c = 'Mass Update Not Processed';
        //opplist.add(opp1);  
        insert opp1;
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = [Select Id, Name From Biomed_Collection_Op_Center__c LIMIT 1];
        
		Id_CollectionOperation = testCollectionOperation1.Id;
        
        //List<sked_Drive__c> DOC = new List<sked_Drive__c>();
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive 1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = siteObj.id,
                                                        sked_Opportunity__c = opp1.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = accobj.id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = 'Draft');
        
        triggerHandler.bypass('OpportunityTriggerHandler');
       
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        insert testDrive1;
        
        
        testDrive1.sked_status__c = 'Cancel';
          
         
        update testDrive1;
        
        List<Opportunity> oppListNew = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        system.debug('oppListNew '+oppListNew);
        for(Opportunity opp : oppListnew)
        {
            system.debug('opp.drive status '+opp.DriveStatus__c);
        }
        Test.startTest();
        UpdateOpportunityStageBatch batchClassInstanceWithMap = new UpdateOpportunityStageBatch(oppListNew);
        Database.executeBatch(batchClassInstanceWithMap);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        List<Opportunity> oppListNewAssert = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        
        Assert.areEqual('Discovery', oppListNew[0].StageName, 'StageName should be updated to "Discovery"');
		Assert.areEqual('Cancelled', oppListNewAssert[0].StageName, 'StageName should be updated to "Cancelled"');
               
    }
    
    static testmethod void testmethod3()
    {
        Test.startTest();
        List<Account> AccList = new List<Account>();
        
        Account accobj = [Select Id, Name, BillingPostalCode, Internal_Name__c From Account LIMIT 1];
        
        Contact conObj = [Select Id, AccountId, FirstName, LastName From Contact LIMIT 1];
        
        accObj.contact_bpl__c = conObj.Id;
        update accObj;
        
        sked__Location__c siteObj = [select id from sked__Location__c limit 1];
        
        
        Opportunity opp2 = new Opportunity();
        opp2.AccountId = accobj.Id;
        opp2.Drive_Site__c = siteObj.Id;
        opp2.Name = 'Test Drive 1';
        opp2.StageName = 'Discovery';
        opp2.Drive_Date__c = System.today().addDays(20);
        opp2.Type_of_Drive__c = 'Mobile';
        opp2.CloseDate = System.today();
        opp2.Start_Time__c = System.now().Time();
        opp2.End_Time__c = System.now().Time()+1;
        opp2.Anticipated_Registered_Donors__c = 10;   
        opp2.Plasma_Pheresis_Projected_Procedures__c = 10;
        opp2.Platelet_Projected_Procedures__c = 11;   
        opp2.Number_of_Platelet_Assets__c = 10;
        opp2.Number_of_Plasma_Assets__c = 10;
        opp2.Number_of_2RBC_Assets__c = 10;
        opp2.Calendar_Description__c = 'Push -35';
        opp2.Online_Donor_Message__c = 'demo';
        opp2.Platelet_Pheresis_Procedures__c = 10;
        opp2.Plasma_Pheresis_Procedures__c = 10;
        opp2.WB_Projected_Procedures__c = 10;
        opp2.WholeBloodProcedureProjectedChangeReason__c = 'demo';
        opp2.X2RBC_Projected_Procedures__c = 10;
        opp2.DoubleRedProceduresProjectedChangeReason__c = 'demo';
        //opp1.sked_Cancellation_Reason__c = 'Staff Shortage';
        //opp1.Initiated_By__c = 'ARC_Initiated_Mobile';
        opp2.Is_Template__c = false;
        opp2.Processing_Status__c = 'Mass Update Not Processed';
       
        TriggerHandler.bypass('OpportunityTriggerHandler'); 
        insert opp2;
        
        OpportunityContactRole OCRole = new OpportunityContactRole(ContactId = conObj.Id, OpportunityId = opp2.Id, Role = 'Primary Contact');
        insert OCRole;
        
         Biomed_Collection_Op_Center__c testCollectionOperation1 = [Select Id, Name From Biomed_Collection_Op_Center__c LIMIT 1];
        
         Id_CollectionOperation = testCollectionOperation1.Id;
        
        //List<sked_Drive__c> DOC = new List<sked_Drive__c>();
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive 1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today().addDays(20),
                                                        sked_Drive_Site__c = siteObj.id,
                                                        sked_Opportunity__c = opp2.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = accobj.id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = 'Hold');
        
        triggerHandler.bypass('OpportunityTriggerHandler');
        //triggerHandler.bypass('DriveTriggerHandler');
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        insert testDrive1;
        
             testDrive1.sked_status__c = 'Confirmed';
             //oppIds.add(doc.sked_Opportunity__c);
         triggerHandler.bypass('DriveTriggerHandler');
        update testDrive1;
       //triggerhandler.clearAllBypass
        List<Opportunity> oppListNew = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];

        
        UpdateOpportunityStageBatch batchClassInstanceWithMap = new UpdateOpportunityStageBatch(oppListNew);
        Database.executeBatch(batchClassInstanceWithMap);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        List<Opportunity> oppListNewAssert = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        
        Assert.areEqual('Discovery', oppListNew[0].StageName, 'StageName should be updated to "Discovery"');
		//Assert.areEqual('Closed', oppListNewAssert[0].StageName, 'StageName should be updated to "Closed"');
        System.debug('new list stage name'+ oppListNewAssert[0].StageName);
               
    }
    
    static testmethod void testmethod4()
    {
        
        Account accobj = [Select Id, Name, BillingPostalCode, Internal_Name__c From Account LIMIT 1];
        
        Contact conObj = [Select Id, AccountId, FirstName, LastName From Contact LIMIT 1];
        
        sked__Location__c siteObj = [Select Id, Name, sked__Address__c, sked_Date_Site_Inspection_Completed__c, sked_Zip_Code__c From sked__Location__c Limit 1];
        
        Opportunity opp1 = [Select Id, AccountId, Drive_Site__c, Name, StageName, Is_Template__c, DriveStatus__c From Opportunity LIMIT 1];
        
        
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = [Select Id, Name From Biomed_Collection_Op_Center__c LIMIT 1];
                 
		Id_CollectionOperation = testCollectionOperation1.Id;
        
        //List<sked_Drive__c> DOC = new List<sked_Drive__c>();
        
        sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive 1',
                                                        sked_Collection_Operation__c = Id_CollectionOperation,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = siteObj.id,
                                                        sked_Opportunity__c = opp1.id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = accobj.id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                     	sked_2RBC_Projected_Procedures__c = 2,
                                                     	sked_WB_Projected_Procedures__c = 2,
                                                        sked_Status__c = 'Hold');
        
        triggerHandler.bypass('OpportunityTriggerHandler');
       
        triggerHandler.bypass('OpportunitySplitTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        insert testDrive1;
        
        List<Opportunity> oppListNew1 = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        for(Opportunity opp : oppListNew1)
        {
            system.debug('opp.drive status123 '+opp.DriveStatus__c);
        }
        
        
        
        //List<sked_Drive__c> docCreatedList = [select id from sked_drive__c where sked_Opportunity__c in :opp1.id];
        
             testDrive1.sked_status__c = 'Draft';
             //oppIds.add(doc.sked_Opportunity__c);
         
        update testDrive1;
        
       //{ opp4.Id => opp4 };
       // oppOldMap.put(opp1.Id, opp1);
        //Opportunity oppa = oppOldMap.get(opp1.Id);
    	//System.debug('DriveStatus__c for opp1 in oppOldMap: ' + oppa.Is_Template__c);
        //sked_Drive__c driveAfterUpdate = [select id, sked_status__c,sked_opportunity__c from sked_drive__C where id =:testDrive1.Id limit 1];
        //system.debug('driveAfterUpdate '+driveAfterUpdate.sked_status__c);
        List<Opportunity> oppListNew = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        system.debug('oppListNew '+oppListNew);
        Map<Id, Opportunity> oppOldMap = new Map<Id, Opportunity>();
        for(Opportunity opp : oppListnew)
        {
            oppOldMap.put(opp.Id, opp);
            system.debug('opp.drive status '+opp.DriveStatus__c);
            Opportunity oppa = oppOldMap.get(opp.Id);
    		System.debug('DriveStatus__c for opp1 in oppOldMap: ' + oppa.DriveStatus__c);
        }
        
        Test.startTest();
        
        UpdateOpportunityStageBatch batchClassInstanceWithMap = new UpdateOpportunityStageBatch(oppListNew1, oppOldMap);
        Database.executeBatch(batchClassInstanceWithMap);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        List<Opportunity> oppListNewAssert = [select id, Is_Template__c,Initiated_By__c, sked_Cancellation_Reason__c,stageName , DriveStatus__c from Opportunity where id= : testDrive1.sked_opportunity__c];
        
        Assert.areEqual('Discovery', oppListNew[0].StageName, 'StageName should be updated to "Discovery"');
		Assert.areEqual('Solicitation', oppListNewAssert[0].StageName, 'StageName should be updated to "Solicitation"');
               
    }
    
    
}