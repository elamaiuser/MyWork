@isTest
public class PortfolioTestDataFactory {
	public static List<Taxonomy__c> createTaxonomies(String zipcode1,String zipcode2) {
        
        if(String.isBlank(zipcode1))
            zipcode1 = '31041';
        
        if(String.isBlank(zipcode2))
            zipcode2 = '31042';
        
        String bioRecruitmentRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE).getRecordTypeId();
        String supervisorRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE).getRecordTypeId();
        String bioAccountRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE).getRecordTypeId();
        String bioFixedSiteRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE).getRecordTypeId();
        String relationshipRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE).getRecordTypeId();
        String sickleCellRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE).getRecordTypeId();
        String nationalAMRTID = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE).getRecordTypeId();
		
        //Bio Recruitment CD
        Taxonomy__c taxover11 = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM', ABM_Key__c=115960, ABM_Name__c='Georgia Coastal ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_755', DRD_Territory_Key__c=115893, DRD_Territory_Name__c='GA South 02', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=bioRecruitmentRTID,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=169, Type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, Zip_Code_Key__c=13272, Zip_Code_Name__c=zipcode1, Zip_Code__c=zipcode1,Version_Key__c=1000);
		Taxonomy__c taxover12 = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM', ABM_Key__c=115960, ABM_Name__c='Georgia Coastal ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_756', DRD_Territory_Key__c=115894, DRD_Territory_Name__c='GA South 03', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=bioRecruitmentRTID,Start_Date__c=System.today()+181,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=169, Type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, Zip_Code_Key__c=13272, Zip_Code_Name__c=zipcode1, Zip_Code__c=zipcode1, Version_Key__c=1001);
		Taxonomy__c taxover21 = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM', ABM_Key__c=115960, ABM_Name__c='Georgia Coastal ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_758', DRD_Territory_Key__c=115853, DRD_Territory_Name__c='GA South 04', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=bioRecruitmentRTID,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=169, Type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, Zip_Code_Key__c=13273, Zip_Code_Name__c=zipcode2, Zip_Code__c=zipcode2,Version_Key__c=1000);
		Taxonomy__c taxover22 = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM1', ABM_Key__c=115961, ABM_Name__c='Georgia Coastal ABM1', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_757', DRD_Territory_Key__c=115895, DRD_Territory_Name__c='GA South 05', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=bioRecruitmentRTID,Start_Date__c=System.today()+181,Team_Code__c='GEOR_S Georgia Coastal1', Team_Key__c=42879, Team_Name__c='GEOR_S Georgia Coastal1', Time_Zone__c='America/New_York', Type_Key__c=169, Type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, Zip_Code_Key__c=13273, Zip_Code_Name__c=zipcode2, Zip_Code__c=zipcode2, Version_Key__c=1001);
		
        //Bio Recruitment Supervisor
        Taxonomy__c taxosupervisor11 = new Taxonomy__c(Supervisor_Code__c='GEOR_S Georgia Coastal Supervisor', Supervisor_Name__c='Georgia Coastal Supervisor', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_755', DRD_Territory_Key__c=115893, DRD_Territory_Name__c='GA South 02', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=supervisorRTID,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=170, Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE, Version_Key__c=1002);
		Taxonomy__c taxosupervisor12 = new Taxonomy__c(Supervisor_Code__c='GEOR_S Georgia Coastal Supervisor', Supervisor_Name__c='Georgia Coastal Supervisor', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_755', DRD_Territory_Key__c=115893, DRD_Territory_Name__c='GA South 02', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=supervisorRTID,Start_Date__c=System.today()+181,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=170, Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE, Version_Key__c=10021);
		Taxonomy__c taxosupervisor21 = new Taxonomy__c(Supervisor_Code__c='GEOR_S Georgia Coastal Supervisor1', Supervisor_Name__c='Georgia Coastal Supervisor1', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_756', DRD_Territory_Key__c=115894, DRD_Territory_Name__c='GA South 03', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=supervisorRTID,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=170, Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE, Version_Key__c=1003);
		Taxonomy__c taxosupervisor22 = new Taxonomy__c(Supervisor_Code__c='GEOR_S Georgia Coastal Supervisor1', Supervisor_Name__c='Georgia Coastal Supervisor1', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_757', DRD_Territory_Key__c=115895, DRD_Territory_Name__c='GA South 05', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=supervisorRTID,Start_Date__c=System.today()+181,Team_Code__c='GEOR_S Georgia Coastal1', Team_Key__c=42879, Team_Name__c='GEOR_S Georgia Coastal1', Time_Zone__c='America/New_York', Type_Key__c=170, Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE, Version_Key__c=10031);
		Taxonomy__c taxosupervisor23 = new Taxonomy__c(Supervisor_Code__c='MNDK_St Cloud_Supervisor', Supervisor_Name__c='MNDK_St Cloud_Supervisor', Division_Code__c='BD34', Division_Key__c=42264, Division_Name__c='North Central', DRD_Territory_Code__c='HProdARC_5000', DRD_Territory_Key__c=115476, DRD_Territory_Name__c='NW North Central 01', DS_Region_Code__c='17E', DS_Region_Key__c=42069, DS_Region_Name__c='Minnesota Dakotas', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=supervisorRTID, Start_Date__c=System.today()-10, Team_Code__c='MNDK_St Cloud', Team_Key__c=42898, Team_Name__c='MNDK_St Cloud', Type_Key__c=170, Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE, Version_Key__c=10032);
		
        
        //Bio Account Portfolio
        Taxonomy__c taxoAccountPortfolio1 = new Taxonomy__c(ABM_Code__c='MNDK_St Cloud_No ABM', ABM_Key__c=115979, ABM_Name__c='No ABM', Division_Code__c='BD34', Division_Key__c=42264, Division_Name__c='North Central', DRD_Territory_Code__c='HProdARC_5000', DRD_Territory_Key__c=115476, DRD_Territory_Name__c='NW North Central 01', DS_Region_Code__c='17E', DS_Region_Key__c=42069, DS_Region_Name__c='Minnesota Dakotas', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=bioAccountRTID, Start_Date__c=System.today()-10, Team_Code__c='MNDK_St Cloud', Team_Key__c=42898, Team_Name__c='MNDK_St Cloud', Type_Key__c=195, Type__c=BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE, Version_Key__c=1316);
		//Taxonomy__c taxoAccountPortfolio2 = new Taxonomy__c(ABM_Code__c='TENN_Western KY_No ABM', ABM_Key__c=116016, ABM_Name__c='No ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdARC_629', DRD_Territory_Key__c=115517, DRD_Territory_Name__c='Western Kentucky 06', DS_Region_Code__c='19E', DS_Region_Key__c=42070, DS_Region_Name__c='Tennessee', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=bioAccountRTID, Start_Date__c=System.today()+1081, Team_Code__c='TENN_Western KY', Team_Key__c=42932, Team_Name__c='TENN_Western KY', Type_Key__c=195, Type__c=BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE, Version_Key__c=13161);
    	
        //Bio Fixed Sites
        Taxonomy__c taxoFixedSite1 = new Taxonomy__c(Collection_Operation_Code__c='BSF_CO_0118', Collection_Operation_Key__c=117514, Collection_Operation_Name__c='Louisville KY', District_Code__c='4076', District_Key__c=214, District_Name__c='Greater Louisville', Division_Code__c='BD32', Division_Key__c=42262, Division_Name__c='Central Atlantic', DS_Region_Code__c='24E', DS_Region_Key__c=117401, DS_Region_Name__c='Kentucky', Portfolio_Code__c='024001804', Portfolio_Name__c='East End Louisville Blood Donation Center', End_Date__c=System.today()+180,RecordTypeId=bioFixedSiteRTID, Start_Date__c=System.today()-10, Type_Key__c=196, Type__c=BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE, Version_Key__c=999);
		Taxonomy__c taxoFixedSite2 = new Taxonomy__c(Collection_Operation_Code__c='BSF_CO_0118', Collection_Operation_Key__c=117514, Collection_Operation_Name__c='Louisville KY', District_Code__c='4076', District_Key__c=214, District_Name__c='Greater Louisville', Division_Code__c='BD32', Division_Key__c=42262, Division_Name__c='Central Atlantic', DS_Region_Code__c='24E', DS_Region_Key__c=117401, DS_Region_Name__c='Kentucky', Portfolio_Code__c='024001804', Portfolio_Name__c='East End Louisville Blood Donation Center', End_Date__c=Date.newInstance(4000, 12, 31),RecordTypeId=bioFixedSiteRTID, Start_Date__c=System.today()+181, Type_Key__c=196, Type__c=BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE, Version_Key__c=9991);

        //Bio Relationship Manager Portfolio
        Taxonomy__c taxoRM = new Taxonomy__c(Division_Code__c='BD35', Division_Key__c=42265, Division_Name__c='Southwest and Rocky Mountain', DS_Region_Code__c='11Z55Z', DS_Region_Key__c=42255, DS_Region_Name__c='Missouri Arkansas', Portfolio_Code__c='MOARED14', Portfolio_Name__c='MOAR Executive Director 05', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=relationshipRTID, Start_Date__c=System.today()-10, Type_Key__c=218, Type__c=BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE, Version_Key__c=694);
                                                   
        //Bio Sickle Cell Portfolio
        Taxonomy__c taxoSickleCell = new Taxonomy__c(Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DS_Region_Code__c='41E', DS_Region_Key__c=42085, DS_Region_Name__c='Alabama Mississippi', Portfolio_Code__c='SAM06', Portfolio_Name__c='Sickle Cell AM 06', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=sickleCellRTID, Start_Date__c=System.today()-10, Type_Key__c=205, Type__c=BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE, Version_Key__c=1317);
		
        //National Account Manager Portfolio
        Taxonomy__c taxoNAM1 = new Taxonomy__c(Portfolio_Code__c='NAM01', Portfolio_Name__c='National Account Manager 01', End_Date__c=System.today()+180, RecordTypeId=nationalAMRTID, Start_Date__c=System.today()-10, Type_Key__c=206, Type__c=BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE, Version_Key__c=2022);
		Taxonomy__c taxoNAM2 = new Taxonomy__c(Portfolio_Code__c='NAM01', Portfolio_Name__c='National Account Manager 01', End_Date__c=Date.newInstance(4000, 12, 31), RecordTypeId=nationalAMRTID, Start_Date__c=System.today()+181, Type_Key__c=206, Type__c=BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE, Version_Key__c=20221);
		
       
        List<Taxonomy__c> taxonomies = new List<Taxonomy__c>();
        taxonomies.add(taxover11);
        taxonomies.add(taxover12);
        taxonomies.add(taxover21);
        taxonomies.add(taxover22);
		taxonomies.add(taxosupervisor11);
        taxonomies.add(taxosupervisor12);
        taxonomies.add(taxosupervisor21);
        taxonomies.add(taxosupervisor22);
        taxonomies.add(taxosupervisor23);
        taxonomies.add(taxoAccountPortfolio1);
        //taxonomies.add(taxoAccountPortfolio2);
        
        taxonomies.add(taxoFixedSite1);
        taxonomies.add(taxoFixedSite2);
        taxonomies.add(taxoRM);
        taxonomies.add(taxoSickleCell); 
        taxonomies.add(taxoNAM1);
        taxonomies.add(taxoNAM2);
        return taxonomies;
	}
}