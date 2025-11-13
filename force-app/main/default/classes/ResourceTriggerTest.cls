/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/16/2023			Barnojit Sharma				Test class for ResourceTrigger (HRP-1566)
 *****************************************************************************************************************************************************************************
*/
@isTest
private class ResourceTriggerTest {
    @TestSetup
    static void makeData() {
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
                            ProfileId = pf.Id,
                            Email = 'test1@yopmail.com',
                            FederationIdentifier = 'test1@yopmail.com',
                            EmployeeNumber = '12345',
                            IsActive = true,
                            FirstName = 'test',
                            LastName = 'test',
                            Username = 'hjgfdxyuigxtryujgh@yopmail.com',
                            EmailEncodingKey = 'ISO-8859-1',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US',
                            Alias = 'test56', 
                            TimeZoneSidKey = 'America/Los_Angeles'
                           );
        insert usr;
        
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType='sked_Territory__c' AND Name = 'District'];

        sked_Territory__c territoryObj1 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt1.Id);

        insert territoryObj1;

        sked_Territory__c territoryObj2 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt2.Id,
                                                               sked_Parent__c = territoryObj1.Id);

        insert territoryObj2;
        
        sked_Territory__c territoryObj3 = new sked_Territory__c(Name = 'Test Territory',
                                                               recordTypeId = rtt3.Id,
                                                               sked_Parent__c = territoryObj2.Id);

        insert territoryObj3;
        
        Biomed_Collection_Op_Center__c collopObj = new Biomed_Collection_Op_Center__c(
                                                                                        Name = 'Test',
                                                                                        Collection_Operation_ID__c = '123456.0',
                                                                                        External_Id__c = 'Bio_Collection_Test',
                                                                                        Staging_Location_Address__c =  '11970 Gager St,Sylmar, California, 91342',
                                                                                        Staging_Location_Geolocation__Latitude__s = 34.280308,
                                                                                        Staging_Location_Geolocation__Longitude__s = -118.393922,
                                                                                        sked_Territory__c = territoryObj3.Id,
                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30', 
                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                        sked_Primary_Scheduler__c = usr.Id
                                                                                     );

        insert collopObj;
      
        sked__Region__c regionObj = new sked__Region__c(sked__Timezone__c = 'America/Los_Angeles',
                                                        Name = 'Test',
                                                        sked__Description__c = 'Test',
                                                        sked_External_Id__c = 'Bio_Collection_Test_America/Los_Angeles',
                                                        sked_Biomed_Collection_Op_Center__c = collopObj.Id,
                                                        sked_Territory__c = territoryObj3.Id
                                                        );

        insert regionObj;
        
        sked__Tag__c tagObj = new sked__Tag__c(Name = 'Inside',
                                                sked__Classification__c = 'Global',
                                                sked__Type__c = 'Physical Location Type'
                                                );

        insert tagObj;
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        sked__Resource__c resourceObj = createResource('Barnojit','Testone','12345','test12@yopmail.com','ULID1234',regionObj.Id,rt.Id);
        insert resourceObj;
    }
    
    @isTest
    static void testMethod1() {
        sked__Resource__c resourceObj = [SELECT Id, sked_Employment_Status__c FROM sked__Resource__c LIMIT 1];
        
        Test.startTest();
        resourceObj.sked_Employment_Status__c = 'Inactive';
        update resourceObj;
        Assert.isTrue('Inactive' == resourceObj.sked_Employment_Status__c);
        Test.stopTest();
    }
    
    @isTest
    static void testMethod2() {
        RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='sked__Resource__c' AND Name = 'Staff'];
        sked__Region__c regionObj = [SELECT Id FROM sked__Region__c LIMIT 1];
        
        Test.startTest();
        sked__Resource__c resourceObj = createResource('Sharma','Testtwo','54321','test321@yopmail.com','ULID4321',regionObj.Id,rt.Id);
        insert resourceObj;
        Assert.isTrue('Sharma' == resourceObj.sked_First_Name__c);
        Test.stopTest();
    }
    
    private static sked__Resource__c createResource(String recFirstName, String recLastName, String empId, String email, String ulId, Id regionId, Id recTy){
        return new sked__Resource__c(
            recordTypeId = recTy,
            sked__Email__c = email,
            sked_Employee_ID__c = empId,
            sked__Is_Active__c = true,
            sked_Title__c = 'Test',
            sked_First_Name__c = recFirstName,
            sked_Preferred_First_Name__c = recFirstName,
            sked_Last_Name__c = recLastName,
            sked_ULID__c = ulId,
            sked__Category__c = 'Employee',
            sked_Employment_Status__c = 'Active',
            sked_Timezone__c = 'America/Los_Angeles',
            sked__Primary_Region__c = regionId,
            sked__Resource_Type__c = 'Person',
            sked_Primary_Phone_Type__c = 'Home Phone',
            sked_Home_Phone__c = '123-123-4321',
            sked__Primary_Phone__c = '123-123-4321',
            sked_Address_Referenced_for_Scheduling__c = 'Work',
            sked_Mobile_Type__c = 'Inside',
            sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
            sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
            sked_Work_Country__c = 'USA',
            sked_Work_City__c = 'Sylmar',
            sked_Work_State__c = 'CA',
            sked_Work_Address_1__c = '11970 Gager St',
            sked_Work_Zip_Code__c = '91342'
        );
    }
}