@isTest(seeAllData=false)
public class BSF_Batch_EndSCOOneTimeTest {
    
    @isTest
    public static void testmethod1() {
        
        Date today = System.today();
        Date endDate = Date.newInstance(4000, 12, 31);
        
        Id taxonomyRTId = Schema.SObjectType.Taxonomy__c
            .getRecordTypeInfosByName()
            .get('Bio Collection BSF')
            .getRecordTypeId();
        
        // ------------------ Taxonomy Version 0 ------------------
        Taxonomy__c taxo = new Taxonomy__c(
            Division_Code__c = 'Div1',
            Division_Key__c = 42068,
            Division_Name__c = 'Div_1',
            DS_Region_Code__c = 'DSR1',
            DS_Region_Key__c = 42069,
            DS_Region_Name__c = 'Reg_1',
            District_Code__c = 'Dist1',
            District_Key__c = 42070,
            District_Name__c = 'District_1',
            Collection_Operation_Name__c = 'CO_2',
            Collection_Operation_Code__c = 'C-OP2',
            Collection_Operation_Key__c = 1111,
            skedulo_region_cd__c = 'SkReg1',
            skedulo_region_name__c = 'SkReg_1',
            Time_Zone__c = 'GMT',
            RecordTypeId = taxonomyRTId,
            Version_Key__c = 0,
            Zip_Code__c = '85671',
            Start_Date__c = today.addDays(-100),
            End_Date__c = endDate
        );
        
        
        insert taxo;
        
        
        Taxonomy__c taxo2 = new Taxonomy__c(Division_Code__c='Div3', Division_Key__c=42068, Division_Name__c='Div_3', 
                                            DS_Region_Code__c='DSR3', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_3', 
                                            District_Code__c='Dist3',District_Key__c=42070,District_Name__c='District_3',
                                            Collection_Operation_Name__c='CO_3',Collection_Operation_Code__c='C-OP3',Collection_Operation_Key__c=1111,
                                            skedulo_region_cd__c='SkReg3',skedulo_region_name__c='SkReg_3',Time_Zone__c='GMT',RecordTypeId=taxonomyRTId,Version_Key__c=0,Zip_Code__c='85671',Start_Date__c=today-100,End_Date__c=today+9);
        
        insert taxo2;
        
        // ------------------ Common Test Data ------------------
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        sked__Location__c mobileSite = (sked__Location__c) mapTestData.get('MOBILE_SITE');
        mobileSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert mobileSite;
        
        sked__Location__c fixedSite = (sked__Location__c) mapTestData.get('FIXED_SITE');
        fixedSite.sked_Zip_Code__c = taxo2.Zip_Code__c;
        insert fixedSite;
        
        // ------------------ Territory ------------------
        Id territoryRTId = Schema.SObjectType.sked_Territory__c
            .getRecordTypeInfosByName()
            .get('District')
            .getRecordTypeId();
        
        sked_Territory__c territory = new sked_Territory__c(
            External_Id__c = 'Bio_Collection_BSF_District_44_' + today,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_District_44',
            Name = 'Territory',
            RecordTypeId = territoryRTId,
            Start_Date__c = today,
            End_Date__c = today.addDays(100)
        );
        insert territory;
        
        // ------------------ Collection Op Center ------------------
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Biomed_Collection_Op_Code_Center_ID__c = 'C-OP3',
            Name = 'Collection Op',
            External_Id__c = 'Bio_Collection_BSF_COP',
            sked_Territory__c = territory.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert co;
        
        // ------------------ Collections Territory ------------------
        Collections_Territory__c collTerr = new Collections_Territory__c(
            Collection_Operation__c = co.Id,
            Zip__c = taxo.Zip_Code__c,
            sked_Start_Date__c = taxo.Start_Date__c,
            sked_End_Date__c = taxo.End_Date__c,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c,
            External_Id__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c + '_' + taxo.Start_Date__c
        );
        insert collTerr;
        // sked__Location__c testSite = [Select Id from sked__Location__c LIMIT 1];
        
        sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
            sked_Site__c = mobileSite.id,
            sked_Collections_Zip_Code__c= collTerr.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Start_Date__c = System.today().addDays(-100),
            sked_End_Date__c = taxo.End_Date__c
        );
        insert testSCO;
        
        
        System.assertNotEquals(
            null,
            testSCO.sked_Collections_Zip_Code__c,
            'Collection Zip Code should not be null'
        );
        
        
        
        // ------------------ Execute Batch ------------------
        Test.startTest();
        BSF_Batch_EndSCOOneTime bse = new BSF_Batch_EndSCOOneTime();
        Database.executeBatch(bse, 1); // batch size is 1
        
        
        Test.stopTest();
        
        
    }
    
    
    @isTest
    public static void testmethod2() {
        
        Date today = System.today();
        Date endDate = Date.newInstance(4000, 12, 31);
        
        Id taxonomyRTId = Schema.SObjectType.Taxonomy__c
            .getRecordTypeInfosByName()
            .get('Bio Collection BSF')
            .getRecordTypeId();
        
        // ------------------ Taxonomy Version 0 ------------------
        Taxonomy__c taxo = new Taxonomy__c(
            Division_Code__c = 'Div1',
            Division_Key__c = 42068,
            Division_Name__c = 'Div_1',
            DS_Region_Code__c = 'DSR1',
            DS_Region_Key__c = 42069,
            DS_Region_Name__c = 'Reg_1',
            District_Code__c = 'Dist1',
            District_Key__c = 42070,
            District_Name__c = 'District_1',
            Collection_Operation_Name__c = 'CO_2',
            Collection_Operation_Code__c = 'C-OP2',
            Collection_Operation_Key__c = 1111,
            skedulo_region_cd__c = 'SkReg1',
            skedulo_region_name__c = 'SkReg_1',
            Time_Zone__c = 'GMT',
            RecordTypeId = taxonomyRTId,
            Version_Key__c = 0,
            Zip_Code__c = '85671',
            Start_Date__c = today.addDays(-100),
            End_Date__c = endDate
        );
        
        
        insert taxo;
        
        
        
        
        // ------------------ Common Test Data ------------------
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        sked__Location__c mobileSite = (sked__Location__c) mapTestData.get('MOBILE_SITE');
        mobileSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert mobileSite;
        
        sked__Location__c fixedSite = (sked__Location__c) mapTestData.get('FIXED_SITE');
        fixedSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert fixedSite;
        
        // ------------------ Territory ------------------
        Id territoryRTId = Schema.SObjectType.sked_Territory__c
            .getRecordTypeInfosByName()
            .get('District')
            .getRecordTypeId();
        
        sked_Territory__c territory = new sked_Territory__c(
            External_Id__c = 'Bio_Collection_BSF_District_44_' + today,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_District_44',
            Name = 'Territory',
            RecordTypeId = territoryRTId,
            Start_Date__c = today,
            End_Date__c = today.addDays(100)
        );
        insert territory;
        
        // ------------------ Collection Op Center ------------------
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Biomed_Collection_Op_Code_Center_ID__c = 'C-OP3',
            Name = 'Collection Op',
            External_Id__c = 'Bio_Collection_BSF_COP',
            sked_Territory__c = territory.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert co;
        
        // ------------------ Collections Territory ------------------
        Collections_Territory__c collTerr = new Collections_Territory__c(
            Collection_Operation__c = co.Id,
            Zip__c = taxo.Zip_Code__c,
            sked_Start_Date__c = taxo.Start_Date__c,
            sked_End_Date__c = taxo.End_Date__c,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c,
            External_Id__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c + '_' + taxo.Start_Date__c
        );
        insert collTerr;
        
        
        sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
            sked_Site__c = mobileSite.id,
            sked_Collections_Zip_Code__c= collTerr.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Start_Date__c = taxo.Start_Date__c.addDays(1),
            sked_End_Date__c = taxo.End_Date__c
        );
        insert testSCO;
        
        
        sked_Site_Collection_Operation__c sco =
            [SELECT Id,
             sked_Collections_Zip_Code__c,
             sked_Collections_Zip_Code__r.External_Id_BackEnd__c
             FROM sked_Site_Collection_Operation__c
             WHERE Id = :testSCO.Id
             LIMIT 1];
        
        
        
        System.assertNotEquals(
            null,
            sco.sked_Collections_Zip_Code__r.External_Id_BackEnd__c,
            'Collection Zip External Id should not be null'
        );
        
        
        
        // ------------------ Execute Batch ------------------
        Test.startTest();
        BSF_Batch_EndSCOOneTime bse = new BSF_Batch_EndSCOOneTime();
        Database.executeBatch(bse, 1); // batch size is 1
        
        
        Test.stopTest();
        
        
    }
    
    
    @isTest
    public static void testmethod3() {
        
        Date today = System.today();
        Date endDate = Date.newInstance(4000, 12, 31);
        
        Id taxonomyRTId = Schema.SObjectType.Taxonomy__c
            .getRecordTypeInfosByName()
            .get('Bio Collection BSF')
            .getRecordTypeId();
        
        // ------------------ Taxonomy Version 0 ------------------
        Taxonomy__c taxo = new Taxonomy__c(
            Division_Code__c = 'Div1',
            Division_Key__c = 42068,
            Division_Name__c = 'Div_1',
            DS_Region_Code__c = 'DSR1',
            DS_Region_Key__c = 42069,
            DS_Region_Name__c = 'Reg_1',
            District_Code__c = 'Dist1',
            District_Key__c = 42070,
            District_Name__c = 'District_1',
            Collection_Operation_Name__c = 'CO_2',
            Collection_Operation_Code__c = 'C-OP2',
            Collection_Operation_Key__c = 1111,
            skedulo_region_cd__c = 'SkReg1',
            skedulo_region_name__c = 'SkReg_1',
            Time_Zone__c = 'GMT',
            RecordTypeId = taxonomyRTId,
            Version_Key__c = 0,
            Zip_Code__c = '85671',
            Start_Date__c = today.addDays(-100),
            End_Date__c = endDate
        );
        
        
        insert taxo;
        
        
        
        
        // ------------------ Common Test Data ------------------
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        sked__Location__c mobileSite = (sked__Location__c) mapTestData.get('MOBILE_SITE');
        mobileSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert mobileSite;
        
        sked__Location__c fixedSite = (sked__Location__c) mapTestData.get('FIXED_SITE');
        fixedSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert fixedSite;
        
        // ------------------ Territory ------------------
        Id territoryRTId = Schema.SObjectType.sked_Territory__c
            .getRecordTypeInfosByName()
            .get('District')
            .getRecordTypeId();
        
        sked_Territory__c territory = new sked_Territory__c(
            External_Id__c = 'Bio_Collection_BSF_District_44_' + today,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_District_44',
            Name = 'Territory',
            RecordTypeId = territoryRTId,
            Start_Date__c = today,
            End_Date__c = today.addDays(100)
        );
        insert territory;
        
        // ------------------ Collection Op Center ------------------
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Biomed_Collection_Op_Code_Center_ID__c = 'C-OP2',
            Name = 'Collection Op',
            External_Id__c = 'Bio_Collection_BSF_COP',
            sked_Territory__c = territory.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert co;
        
        // ------------------ Collections Territory ------------------
        Collections_Territory__c collTerr = new Collections_Territory__c(
            Collection_Operation__c = co.Id,
            Zip__c = taxo.Zip_Code__c,
            sked_Start_Date__c = taxo.Start_Date__c,
            sked_End_Date__c = taxo.End_Date__c,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c,
            External_Id__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c + '_' + taxo.Start_Date__c
        );
        insert collTerr;
        // ------------------ Collections Territory ------------------
        Collections_Territory__c collTerr1 = new Collections_Territory__c(
            Collection_Operation__c = co.Id,
            Zip__c = taxo.Zip_Code__c,
            sked_Start_Date__c = taxo.Start_Date__c-1,
            sked_End_Date__c = taxo.End_Date__c,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_CollZip_5345' ,
            External_Id__c = 'Bio_Collection_BSF_CollZip_' + '5345' + '_' + taxo.Start_Date__c
        );
        insert collTerr1;
        
        sked_Site_Collection_Operation__c testSCO = new sked_Site_Collection_Operation__c(
            sked_Site__c = mobileSite.id,
            sked_Collections_Zip_Code__c= collTerr.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Start_Date__c =  taxo.Start_Date__c-1,
            sked_End_Date__c = taxo.End_Date__c
        );
        insert testSCO;
        
        sked_Site_Collection_Operation__c testSCO1 = new sked_Site_Collection_Operation__c(
            sked_Site__c = mobileSite.id,
            sked_Collections_Zip_Code__c= collTerr.Id,
            sked_Collection_Operation__c = co.Id,
            sked_Start_Date__c = taxo.Start_Date__c.addDays(1),
            sked_End_Date__c = taxo.End_Date__c
        );
        insert testSCO1;
        
        System.assertNotEquals(
            null,
            testSCO.sked_Collections_Zip_Code__c,
            'Collection Zip Code should not be null'
        );
        
        
        // ------------------ Execute Batch ------------------
        Test.startTest();
        BSF_Batch_EndSCOOneTime bse = new BSF_Batch_EndSCOOneTime();
        Database.executeBatch(bse, 1); // batch size is 1
        
        
        Test.stopTest();
        
        
    }
    
    
    
    @isTest
    public static void testmethod4() {
        
        Date today = System.today();
        Date endDate = Date.newInstance(4000, 12, 31);
        
        Id taxonomyRTId = Schema.SObjectType.Taxonomy__c
            .getRecordTypeInfosByName()
            .get('Bio Collection BSF')
            .getRecordTypeId();
        
        // ------------------ Taxonomy Version 0 ------------------
        Taxonomy__c taxo = new Taxonomy__c(
            Division_Code__c = 'Div1',
            Division_Key__c = 42068,
            Division_Name__c = 'Div_1',
            DS_Region_Code__c = 'DSR1',
            DS_Region_Key__c = 42069,
            DS_Region_Name__c = 'Reg_1',
            District_Code__c = 'Dist1',
            District_Key__c = 42070,
            District_Name__c = 'District_1',
            Collection_Operation_Name__c = 'CO_2',
            Collection_Operation_Code__c = 'C-OP2',
            Collection_Operation_Key__c = 1111,
            skedulo_region_cd__c = 'SkReg1',
            skedulo_region_name__c = 'SkReg_1',
            Time_Zone__c = 'GMT',
            RecordTypeId = taxonomyRTId,
            Version_Key__c = 0,
            Zip_Code__c = '85671',
            Start_Date__c = today.addDays(-100),
            End_Date__c = endDate
        );
        
        
        insert taxo;
        
        
        
        
        // ------------------ Common Test Data ------------------
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
        
        sked__Location__c mobileSite = (sked__Location__c) mapTestData.get('MOBILE_SITE');
        mobileSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert mobileSite;
        
        sked__Location__c fixedSite = (sked__Location__c) mapTestData.get('FIXED_SITE');
        fixedSite.sked_Zip_Code__c = taxo.Zip_Code__c;
        insert fixedSite;
        
        // ------------------ Territory ------------------
        Id territoryRTId = Schema.SObjectType.sked_Territory__c
            .getRecordTypeInfosByName()
            .get('District')
            .getRecordTypeId();
        
        sked_Territory__c territory = new sked_Territory__c(
            External_Id__c = 'Bio_Collection_BSF_District_44_' + today,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_District_44',
            Name = 'Territory',
            RecordTypeId = territoryRTId,
            Start_Date__c = today,
            End_Date__c = today.addDays(100)
        );
        insert territory;
        
        // ------------------ Collection Op Center ------------------
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c(
            Biomed_Collection_Op_Code_Center_ID__c = 'C-OP3',
            Name = 'Collection Op',
            External_Id__c = 'Bio_Collection_BSF_COP',
            sked_Territory__c = territory.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30'
        );
        insert co;
        
        // ------------------ Collections Territory ------------------
        Collections_Territory__c collTerr = new Collections_Territory__c(
            Collection_Operation__c = co.Id,
            Zip__c = taxo.Zip_Code__c,
            sked_Start_Date__c = taxo.Start_Date__c.addDays(1),
            sked_End_Date__c = taxo.End_Date__c,
            External_Id_BackEnd__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c,
            External_Id__c = 'Bio_Collection_BSF_CollZip_' + taxo.Zip_Code__c + '_' + taxo.Start_Date__c
        );
        insert collTerr;
        
        
        System.assertNotEquals(
            null,
            collTerr.Id,
            'Collection Zip Code should not be null'
        );
        
        
        
        
        // ------------------ Execute Batch ------------------
        Test.startTest();
        BSF_Batch_EndSCOOneTime bse = new BSF_Batch_EndSCOOneTime();
        Database.executeBatch(bse, 1); // batch size is 1
        
        
        Test.stopTest();
        
        
    }
    
}