@isTest
public class BSF_Batch_CollectionZipOneTime_test 
{
    
    @isTest
    public static void testmethod1()
    {
        Date today = system.Today();
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
        Taxonomy__c taxo = new Taxonomy__c(Division_Code__c='Div1', Division_Key__c=42068, Division_Name__c='Div_1', 
                                           DS_Region_Code__c='DSR1', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_1', 
                                           District_Code__c='Dist1',District_Key__c=42070,District_Name__c='District_1',
                                           Collection_Operation_Name__c='CO_2',Collection_Operation_Code__c='C-OP2',Collection_Operation_Key__c=1111,
                                           skedulo_region_cd__c='SkReg1',skedulo_region_name__c='SkReg_1',Time_Zone__c='GMT',RecordTypeId=recordTypeId,Version_Key__c=0,Zip_Code__c='85671',Start_Date__c=today-100,End_Date__c=today+9);
        Taxonomy__c taxo2 = new Taxonomy__c(Division_Code__c='Div3', Division_Key__c=42068, Division_Name__c='Div_3', 
                                            DS_Region_Code__c='DSR3', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_3', 
                                            District_Code__c='Dist3',District_Key__c=42070,District_Name__c='District_3',
                                            Collection_Operation_Name__c='CO_3',Collection_Operation_Code__c='C-OP3',Collection_Operation_Key__c=1111,
                                            skedulo_region_cd__c='SkReg3',skedulo_region_name__c='SkReg_3',Time_Zone__c='GMT',RecordTypeId=recordTypeId,Version_Key__c=0,Zip_Code__c='85672',Start_Date__c=today-100,End_Date__c=today+9);
        
        insert taxo;
        
        insert taxo2;
        
        Taxonomy__c taxo_1 = new Taxonomy__c(Collection_Operation_Code__c='C_op_01',Collection_Operation_Key__c=1111,Collection_Operation_Name__c='COllection_01',District_Code__c='Dis_01',District_Name__c='District_01',Division_Code__c='Div_01',Division_Key__c=1111,Division_Name__c='Division_01',DS_Region_Code__c='DSR_01',DS_Region_Key__c=1111,DS_Region_Name__c='DSRegion_01',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_01',skedulo_region_key__c=111,skedulo_region_name__c='SKRegion_01',Time_Zone__c='GMT',Zip_Code__c='90943',Start_Date__c=today+10,End_Date__c=Date.newInstance(4000,12,31),Version_Key__c=1);
        Taxonomy__c taxo_2 = new Taxonomy__c(Collection_Operation_Code__c='C_op_02',Collection_Operation_Key__c=1112,Collection_Operation_Name__c='COllection_02',District_Code__c='Dis_02',District_Name__c='District_02',Division_Code__c='Div_02',Division_Key__c=1112,Division_Name__c='Division_02',DS_Region_Code__c='DSR_02',DS_Region_Key__c=1112,DS_Region_Name__c='DSRegion_02',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_02',skedulo_region_key__c=112,skedulo_region_name__c='SKRegion_02',Time_Zone__c='GMT',Zip_Code__c='85671',Start_Date__c=today+1,End_Date__c=Date.newInstance(4000,12,31),Version_Key__c=1);
        List<Taxonomy__c> taxonomyVersionOne = new List<Taxonomy__c>{taxo_1,taxo_2};
            
            insert taxonomyVersionOne;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Zip_Code__c=taxo_1.Zip_Code__c;
        insert testMobileSite;
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        testMobileSite.sked_Zip_Code__c=taxo2.Zip_Code__c;
        insert testFixedSite;
        
        
        recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District'+'_'+44+'_'+system.today();
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+44;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='C-OP3';
        //co.Collection_Operation_ID__c='CoKey';
        co.Name='Collection_Operation_Name__c';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Territory__c=territory.id;
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
        insert co;
        
        Collections_Territory__c collTerr = new Collections_Territory__c();
        collTerr.Collection_Operation__c = co.Id;
        collTerr.Zip__c = taxo2.Zip_Code__c;
        collTerr.sked_Start_Date__c = taxo2.Start_Date__c;
        collTerr.sked_End_Date__c = taxo2.End_Date__c;
        
        insert collTerr;
        
        
        Test.startTest();
        BSF_Batch_CollectionZipOneTime batch = new BSF_Batch_CollectionZipOneTime(true,false);
        
        id jobid = database.executeBatch(batch,200);
        system.assert(jobid!=null, True);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testmethod2()
    {
        Date today = system.Today();
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
        Taxonomy__c taxo = new Taxonomy__c(Division_Code__c='Div1', Division_Key__c=42068, Division_Name__c='Div_1', 
                                           DS_Region_Code__c='DSR1', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_1', 
                                           District_Code__c='Dist1',District_Key__c=42070,District_Name__c='District_1',
                                           Collection_Operation_Name__c='CO_2',Collection_Operation_Code__c='C-OP2',Collection_Operation_Key__c=1111,
                                           skedulo_region_cd__c='SkReg1',skedulo_region_name__c='SkReg_1',Time_Zone__c='GMT',RecordTypeId=recordTypeId,Version_Key__c=0,Zip_Code__c='85671',Start_Date__c=today-100,End_Date__c=today+9);
        Taxonomy__c taxo2 = new Taxonomy__c(Division_Code__c='Div3', Division_Key__c=42068, Division_Name__c='Div_3', 
                                            DS_Region_Code__c='DSR3', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_3', 
                                            District_Code__c='Dist3',District_Key__c=42070,District_Name__c='District_3',
                                            Collection_Operation_Name__c='CO_3',Collection_Operation_Code__c='C-OP3',Collection_Operation_Key__c=1111,
                                            skedulo_region_cd__c='SkReg3',skedulo_region_name__c='SkReg_3',Time_Zone__c='GMT',RecordTypeId=recordTypeId,Version_Key__c=0,Zip_Code__c='85672',Start_Date__c=today-100,End_Date__c=today+9);
        
        insert taxo;
        
        insert taxo2;
        
        Taxonomy__c taxo_1 = new Taxonomy__c(Collection_Operation_Code__c='C_op_01',Collection_Operation_Key__c=1111,Collection_Operation_Name__c='COllection_01',District_Code__c='Dis_01',District_Name__c='District_01',Division_Code__c='Div_01',Division_Key__c=1111,Division_Name__c='Division_01',DS_Region_Code__c='DSR_01',DS_Region_Key__c=1111,DS_Region_Name__c='DSRegion_01',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_01',skedulo_region_key__c=111,skedulo_region_name__c='SKRegion_01',Time_Zone__c='GMT',Zip_Code__c='90943',Start_Date__c=today+10,End_Date__c=Date.newInstance(4000,12,31),Version_Key__c=1);
        Taxonomy__c taxo_2 = new Taxonomy__c(Collection_Operation_Code__c='C_op_02',Collection_Operation_Key__c=1112,Collection_Operation_Name__c='COllection_02',District_Code__c='Dis_02',District_Name__c='District_02',Division_Code__c='Div_02',Division_Key__c=1112,Division_Name__c='Division_02',DS_Region_Code__c='DSR_02',DS_Region_Key__c=1112,DS_Region_Name__c='DSRegion_02',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_02',skedulo_region_key__c=112,skedulo_region_name__c='SKRegion_02',Time_Zone__c='GMT',Zip_Code__c='85671',Start_Date__c=today+1,End_Date__c=Date.newInstance(4000,12,31),Version_Key__c=1);
        List<Taxonomy__c> taxonomyVersionOne = new List<Taxonomy__c>{taxo_1,taxo_2};
            
            insert taxonomyVersionOne;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Zip_Code__c=taxo_1.Zip_Code__c;
        insert testMobileSite;
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        testMobileSite.sked_Zip_Code__c=taxo2.Zip_Code__c;
        insert testFixedSite;
        
        
        recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District'+'_'+44+'_'+system.today();
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+44;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='C-OP3';
        //co.Collection_Operation_ID__c='CoKey';
        co.Name='Collection_Operation_Name__c';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Territory__c=territory.id;
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
        insert co;
        
        Collections_Territory__c collTerr = new Collections_Territory__c();
        collTerr.Collection_Operation__c = co.Id;
        collTerr.Zip__c = taxo2.Zip_Code__c;
        collTerr.sked_Start_Date__c = taxo2.Start_Date__c;
        collTerr.sked_End_Date__c = taxo2.End_Date__c;
        
        insert collTerr;
        
        sked_Site_Collection_Operation__c newSiteCO = new sked_Site_Collection_Operation__c
            (
                sked_Collection_Operation__c = co.Id,
                sked_Site__c = testMobileSite.Id,
                sked_Collections_Zip_Code__c =collTerr.Id,
                sked_Start_Date__c = collTerr.sked_Start_Date__c,
                sked_End_Date__c = collTerr.sked_End_Date__c);
        insert newSiteCO;
        Test.startTest();
        BSF_Batch_CollectionZipOneTime batch = new BSF_Batch_CollectionZipOneTime(false,True);
        
        id jobid = database.executeBatch(batch,200);
        system.assert(jobid!=null, True);
        Test.stopTest();
    }
}