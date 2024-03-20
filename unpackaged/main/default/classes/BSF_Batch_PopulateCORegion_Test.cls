@isTest
public class BSF_Batch_PopulateCORegion_Test 
{
	@isTest
    public static void testmethod1()
    {
        Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
        Taxonomy__c taxo = new Taxonomy__c(Division_Code__c='Div1', Division_Key__c=42068, Division_Name__c='Div_1', 
                                             DS_Region_Code__c='DSR1', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_1', 
                                             District_Code__c='Dist1',District_Key__c=42070,District_Name__c='District_1',
                                             Collection_Operation_Name__c='CO_2',Collection_Operation_Code__c='C-OP2',Collection_Operation_Key__c=1111,
                                             skedulo_region_cd__c='SkReg1',skedulo_region_name__c='SkReg_1',Time_Zone__c='GMT',RecordTypeId=recordTypeId);
        
        insert taxo;
        
        Taxonomy__c taxo_1 = new Taxonomy__c(Collection_Operation_Code__c='C_op_01',Collection_Operation_Key__c=1111,Collection_Operation_Name__c='COllection_01',District_Code__c='Dis_01',District_Name__c='District_01',Division_Code__c='Div_01',Division_Key__c=1111,Division_Name__c='Division_01',DS_Region_Code__c='DSR_01',DS_Region_Key__c=1111,DS_Region_Name__c='DSRegion_01',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_01',skedulo_region_key__c=111,skedulo_region_name__c='SKRegion_01',Time_Zone__c='GMT',Zip_Code__c='90943',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=1);
        Taxonomy__c taxo_2 = new Taxonomy__c(Collection_Operation_Code__c='C_op_02',Collection_Operation_Key__c=1112,Collection_Operation_Name__c='COllection_02',District_Code__c='Dis_02',District_Name__c='District_02',Division_Code__c='Div_02',Division_Key__c=1112,Division_Name__c='Division_02',DS_Region_Code__c='DSR_02',DS_Region_Key__c=1112,DS_Region_Name__c='DSRegion_02',RecordTypeId =recordTypeId,skedulo_region_cd__c='SKR_02',skedulo_region_key__c=112,skedulo_region_name__c='SKRegion_02',Time_Zone__c='GMT',Zip_Code__c='85671',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=1);
        List<Taxonomy__c> taxonomyVersionOne = new List<Taxonomy__c>{taxo_1,taxo_2};
        
        insert taxonomyVersionOne;
        
       
        
        
        
        
        Test.startTest();
        BSF_Batch_PopulateCORegion batch = new BSF_Batch_PopulateCORegion();
        id jobid = database.executeBatch(batch,200);
        system.assert(jobid!=null, True);
        /*BSF_setting__c setting =new BSF_setting__c();
        setting.LastCollectionOperationRun__c=taxo.createdDate;
        setting.LastId__c=taxo.id;
        insert setting;
        taxonomy__c tx =[SELECT Id FROM Taxonomy__c WHERE RecordType.Name = 'Bio Collection BSF'
                AND Id > :setting.LastId__c
                AND CreatedDate > :setting.LastCollectionOperationRun__c
                ORDER BY Id ASC
                LIMIT 1];
        system.debug(system.today());
        system.debug(tx);*/
        
        
      
        
        /*string externalId = 'Bio_Collection_BSF_' + taxo_1.Collection_Operation_Code__c+'_'+taxo_1.Time_Zone__c;
        system.debug('Bio_Collection_BSF_'+externalId);
        List<Sked__Region__c> skRegion = [select Name,sked_Biomed_Collection_Op_Center__r.Name,sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name,
                                        sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name
                                        from Sked__Region__c];
        List<Biomed_Collection_Op_Center__c> coll=[select id from Biomed_Collection_Op_Center__c];
        system.debug('coll'+coll);
        system.debug('skRegion:'+skRegion);
        List<sked_Territory__c> terr=[select id,recordtype.name from sked_Territory__c];
        system.debug('terr'+terr);
        system.assertEquals(skRegion.Name,taxo_1.skedulo_region_name__c);
        system.assertEquals(skRegion.sked_Biomed_Collection_Op_Center__r.Name,taxo_1.Collection_Operation_Name__c);
        system.assertEquals(skRegion.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name,taxo_1.Division_Name__c);
        system.assertEquals(skRegion.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,taxo_1.District_Name__c);
        
        Taxonomy__c taxo_3 = new Taxonomy__c(Collection_Operation_Code__c='C_op_01',Collection_Operation_Key__c=1111,Collection_Operation_Name__c='COllection_01',District_Code__c='Dis_01',District_Name__c='District_01',Division_Code__c='Div_01',Division_Key__c=1111,Division_Name__c='Division_01',DS_Region_Code__c='DSR_01',DS_Region_Key__c=1111,DS_Region_Name__c='DSRegion_01',RecordTypeId ='012q00000006NO0AAM',skedulo_region_cd__c='SKR_01',skedulo_region_key__c=111,skedulo_region_name__c='SKRegion_01',Time_Zone__c='GMT',Zip_Code__c='90943',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=2);
        Taxonomy__c taxo_4 = new Taxonomy__c(Collection_Operation_Code__c='C_op_02',Collection_Operation_Key__c=1112,Collection_Operation_Name__c='COllection_02',District_Code__c='Dis_02',District_Name__c='District_02',Division_Code__c='Div_02',Division_Key__c=1112,Division_Name__c='Division_02',DS_Region_Code__c='DSR_02',DS_Region_Key__c=1112,DS_Region_Name__c='DSRegion_02',RecordTypeId ='012q00000006NO0AAM',skedulo_region_cd__c='SKR_02',skedulo_region_key__c=112,skedulo_region_name__c='SKRegion_02',Time_Zone__c='GMT',Zip_Code__c='85671',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=2);
        Taxonomy__c taxo_5 = new Taxonomy__c(Collection_Operation_Code__c='C_op_03',Collection_Operation_Key__c=1113,Collection_Operation_Name__c='COllection_03',District_Code__c='Dis_01',District_Name__c='District_01',Division_Code__c='Div_01',Division_Key__c=1111,Division_Name__c='Division_01',DS_Region_Code__c='DSR_01',DS_Region_Key__c=1111,DS_Region_Name__c='DSRegion_01',RecordTypeId ='012q00000006NO0AAM',skedulo_region_cd__c='SKR_01',skedulo_region_key__c=111,skedulo_region_name__c='SKRegion_01',Time_Zone__c='GMT',Zip_Code__c='90943',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=2);
        Taxonomy__c taxo_6= new Taxonomy__c(Collection_Operation_Code__c='C_op_04',Collection_Operation_Key__c=1114,Collection_Operation_Name__c='COllection_04',District_Code__c='Dis_02',District_Name__c='District_02',Division_Code__c='Div_02',Division_Key__c=1112,Division_Name__c='Division_02',DS_Region_Code__c='DSR_02',DS_Region_Key__c=1112,DS_Region_Name__c='DSRegion_02',RecordTypeId ='012q00000006NO0AAM',skedulo_region_cd__c='SKR_02',skedulo_region_key__c=112,skedulo_region_name__c='SKRegion_02',Time_Zone__c='GMT',Zip_Code__c='85671',Start_Date__c=Date.newInstance(2022,01,01),End_Date__c=Date.newInstance(2022,11,31),Version_Key__c=2);
        
        
        
BSF_Batch_PopulateCORegion batch1 = new BSF_Batch_PopulateCORegion();
        database.executeBatch(batch,200);
    
        integer I = [select count() from  sked_Territory__c where recordType.name='Division'];
        system.assertEquals(I, 2);
        
        externalId = 'Bio_Collection_BSF' + taxo_5.Collection_Operation_Code__c+'_'+taxo_5.Time_Zone__c;
        Sked__Region__c skRegion1 = [select Name,sked_Biomed_Collection_Op_Center__r.Name,sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name,
                                        sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name
                                        from Sked__Region__c where sked_External_Id__c=:externalId];
        system.assertEquals(skRegion1.Name,taxo_5.skedulo_region_name__c);
        system.assertEquals(skRegion1.sked_Biomed_Collection_Op_Center__r.Name,taxo_5.Collection_Operation_Name__c);
        system.assertEquals(skRegion1.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name,taxo_5.Division_Name__c);
        system.assertEquals(skRegion1.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.sked_Parent__r.Name,taxo_5.District_Name__c);*/
    Test.stopTest();
    }
    
    @isTest
    public static void testmethod2()
    {
        Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get('District').getRecordTypeId();
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+'District'+'_'+44+'_'+system.today();
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+'District'+'_'+44;
        territory.Name = 'name';
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = system.today();
        territory.End_Date__c = system.today().addDays(100);
        
        
        insert territory;
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c ='BSF_Co_005';
        co.Collection_Operation_ID__c='CoKey';
        co.Name='Collection_Operation_Name__c';
        co.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        co.sked_Territory__c=territory.id;
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
         insert co;
        
         sked_Territory_Collection_Operation__c terrCollOpp = new sked_Territory_Collection_Operation__c();
        terrCollOpp.sked_Start_Date__c = territory.Start_Date__c;
        terrCollOpp.sked_End_Date__c = territory.End_Date__c;
        terrCollOpp.sked_External_ID__c = territory.External_Id__c+'__'+co.Biomed_Collection_Op_Code_Center_ID__c;
        terrCollOpp.sked_Territory__c = territory.id;
        terrCollOpp.sked_Collection_Operation__c =co.id;
        
        insert terrCollOpp;
        terrCollOpp.sked_Start_Date__c = system.today().addDays(1);
        update terrCollOpp;
        test.startTest();
        territory.End_Date__c=system.today().addDays(50);
        territory.Start_Date__c = system.today().adddays(1);
        
        update territory;
        test.stopTest();
        
        
    }
}