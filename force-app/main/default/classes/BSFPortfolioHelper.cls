/***
*  BSFPortfolioHelper class.
*  This Helper class would be called from a batch when new GOATS Bio Recruitment data is received into BSF. It creates
*  BSF Portfolio records for each new unique node in data taxonomy data and updates labels if there is any change.
*  This does not delete the old portfolio(territory/AM) records if the portfolio is moved to  new team/DM, it creates new record with same attributes under new team/DM.
*/
/*
* Modification Log
* Date					     Developer Name			     Comments
* *******************************************************************************************************************************************************************************************************
* 11/26/2024                  Balaji N                   Logic for HRP-13866 Method:createOrUpdatePortfolio System.Label.NO_SBPM_ABM in place of hard coded value
*********************************************************************************************************************************************************************************************************
*/
public with sharing class BSFPortfolioHelper {
    /* HRP-1707 */
    public static void processTaxonomyData(Decimal taxoVerKey,String recordTypeName){
        BSFPortfolioHelper protfolioHelper = new BSFPortfolioHelper();
        List<Taxonomy__c> taxonomyRecords = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                             Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
                                             RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
                                             FROM Taxonomy__c WHERE Version_Key__c = :taxoVerKey AND RecordType.Name = :recordTypeName ];
        protfolioHelper.createOrUpdatePortfolio(taxonomyRecords);
    }
    public void createOrUpdatePortfolio(List<Taxonomy__c> taxonomyRecords){
        System.debug('taxonomyRecords -> '+taxonomyRecords.size());
        Set<String> externalKeySet = new Set<String>();
        Map<String,BSF_Portfolio__c> divisionPortfolioMap = new Map<String,BSF_Portfolio__c>(); //DSVP
        Map<String,BSF_Portfolio__c> regionPortfolioMap = new Map<String,BSF_Portfolio__c>(); //RDSE
        Map<String,BSF_Portfolio__c> abmPortfolioMap = new Map<String,BSF_Portfolio__c>();//ABM
        Map<String,BSF_Portfolio__c> teamPortfolioMap = new Map<String,BSF_Portfolio__c>(); //DM
        Map<String,BSF_Portfolio__c> territoryPortfolioMap = new Map<String,BSF_Portfolio__c>(); //AM
        Map<String,BSF_Portfolio__c> nonGeographicNode1Map = new Map<String,BSF_Portfolio__c>();//SAM,RAM,NAM,PB,Supervisor AM, Fixed Site
        Map<String,BSF_Portfolio__c> supervisorPortfolioMap = new Map<String,BSF_Portfolio__c>(); //Supervisor
        Map<String,BSF_Portfolio__c> districtPortfolioMap = new Map<String,BSF_Portfolio__c>(); //District
        Map<String,BSF_Portfolio__c> collectionOpPortfolioMap = new Map<String,BSF_Portfolio__c>(); //Collection Operartion
        for(Taxonomy__c taxoRecord:taxonomyRecords){
            Set<String> taxoNodes = BSF_Utilities.getTaxonomyNodes(taxoRecord.RecordType.Name);
            String keyValue = taxoRecord.RecordType.Name;
            if(taxoNodes == null)
                continue;
            System.debug('taxoNodes ->'+taxoNodes);
            if(taxoNodes.contains('Division_Code__c')){
                if(!externalKeySet.contains(taxoRecord.Division_Code__c)){
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.Division_Code__c,taxoRecord.Division_Name__c,null,keyValue,'DSVP',divisionPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue +'_'+ taxoRecord.Division_Code__c;
                }
            }
            if(taxoNodes.contains('DS_Region_Code__c')){
                if(!externalKeySet.contains(keyValue +'_'+taxoRecord.DS_Region_Code__c)){
                    String parentKey = keyValue;
                    if(taxoRecord.RecordType.Name == BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE){
                        parentKey = null;
                    }
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.DS_Region_Code__c,taxoRecord.DS_Region_Name__c,parentKey,keyValue,'RDSE',regionPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue +'_'+taxoRecord.DS_Region_Code__c;
                }
            }
            if(taxoNodes.contains('District_Code__c')){
                if(!externalKeySet.contains(keyValue +'_'+taxoRecord.District_Code__c)){
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.District_Code__c,taxoRecord.District_Name__c,keyValue,keyValue,'DISTRICT',districtPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue +'_'+taxoRecord.District_Code__c;
                }
            }
            if(taxoNodes.contains('Collection_Operation_Code__c')){
                if(!externalKeySet.contains(keyValue +'_'+taxoRecord.Collection_Operation_Code__c)){
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.Collection_Operation_Code__c,taxoRecord.Collection_Operation_Name__c,keyValue,keyValue,'Collection Operation',collectionOpPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue +'_'+taxoRecord.Collection_Operation_Code__c;
                }
            }
            if(taxoNodes.contains('Team_Code__c')){
                if(!externalKeySet.contains(keyValue+'_'+taxoRecord.Team_Code__c)){
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.Team_Code__c,taxoRecord.Team_Name__c,keyValue,keyValue,BSF_Constants.DISTRICT_MANAGER,teamPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue + '_'+taxoRecord.Team_Code__c;
                }
                // 3807
                // Clone DISTRICT_MANAGER record and create ACCOUNT_SPECIALIST record
                if(!externalKeySet.contains(keyValue+'_'+taxoRecord.Team_Code__c)){
                    createPortfolioRecordForAs(taxoRecord,taxoRecord.Team_Code__c,taxoRecord.Team_Name__c,BSF_Constants.ACCOUNT_SPECIALIST,teamPortfolioMap,externalKeySet);
                }
            }
            if(taxoNodes.contains('Supervisor_Code__c')){
                if(!externalKeySet.contains(keyValue+'_'+taxoRecord.Supervisor_Code__c)){
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.Supervisor_Code__c,taxoRecord.Supervisor_Name__c,keyValue,keyValue,BSF_Constants.SUPERVISOR,supervisorPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue + '_'+taxoRecord.Supervisor_Code__c;
                }
            }
            if(taxoNodes.contains('ABM_Code__c')){
                if(taxoRecord.ABM_Name__c != null && taxoRecord.ABM_Name__c != 'NA' && !taxoRecord.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM)){//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
                    if(!externalKeySet.contains(keyValue+'_'+taxoRecord.ABM_Code__c)){
                        keyValue = createPortfolioRecord(taxoRecord,taxoRecord.ABM_Code__c,taxoRecord.ABM_Name__c,keyValue,keyValue,BSF_Constants.AREA_BOOKING_MANAGER,abmPortfolioMap,externalKeySet);
                    }else{
                        keyValue = keyValue + '_'+taxoRecord.ABM_Code__c;
                    }
                }
            }
            if(taxoNodes.contains('DRD_Territory_Code__c')){
                if(!externalKeySet.contains(keyValue+'_'+taxoRecord.DRD_Territory_Code__c)){
                    String portType = BSF_Utilities.getPortFolioType(taxoRecord.RecordType.Name);
                    system.debug('DRD_Territory_Code__c');
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.DRD_Territory_Code__c,taxoRecord.DRD_Territory_Name__c,keyValue,keyValue,portType,territoryPortfolioMap,externalKeySet);
                }else{
                    keyValue = keyValue + '_'+taxoRecord.DRD_Territory_Code__c;
                }
            }
            if(taxoNodes.contains('Portfolio_Code__c')){
                if(!externalKeySet.contains(keyValue+'_'+taxoRecord.Portfolio_Code__c)){
                    String portType = BSF_Utilities.getPortFolioType(taxoRecord.RecordType.Name);
                    String parentKey = keyValue;
                    if(taxoRecord.RecordType.Name == BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE){
                        parentKey = null;
                    }
                    keyValue = createPortfolioRecord(taxoRecord,taxoRecord.Portfolio_Code__c,taxoRecord.Portfolio_Name__c,parentKey,keyValue,portType,nonGeographicNode1Map,externalKeySet);
                }else{
                    keyValue = keyValue + '_'+taxoRecord.Portfolio_Code__c;
                }
            }
        }//end of for
        Schema.SObjectField extField = BSF_Portfolio__c.Fields.External_Key__c;
        List<BSF_Portfolio__c> divisionPortfolioTobeUpsert = dmldecision(divisionPortfolioMap.values());
        Database.UpsertResult[] divisionUpsert = Database.upsert(divisionPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> regionPortfolioTobeUpsert = dmldecision(regionPortfolioMap.values());
        Database.UpsertResult[] regionUpsert = Database.upsert(regionPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> districtPortfolioTobeUpsert = dmldecision(districtPortfolioMap.values());
        Database.UpsertResult[] districtUpsert = Database.upsert(districtPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> collOpPortfolioTobeUpsert = dmldecision(collectionOpPortfolioMap.values());
        Database.UpsertResult[] collOpUpsert = Database.upsert(collOpPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> dmPortfolioTobeUpsert = dmldecision(teamPortfolioMap.values());
        Database.UpsertResult[] dmUpsert = Database.upsert(dmPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> abmPortfolioTobeUpsert = dmldecision(abmPortfolioMap.values());
        Database.UpsertResult[] abmUpsert = Database.upsert(abmPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> supPortfolioTobeUpsert = dmldecision(supervisorPortfolioMap.values());
        Database.UpsertResult[] supUpsert = Database.upsert(supPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> amPortfolioTobeUpsert = dmldecision(territoryPortfolioMap.values());
        Database.UpsertResult[] amUpsert = Database.upsert(amPortfolioTobeUpsert, extField, false);
        List<BSF_Portfolio__c> nonGeoPortfolioTobeUpsert = dmldecision(nonGeographicNode1Map.values());
        Database.UpsertResult[] nonGeoUpsert = Database.upsert(nonGeoPortfolioTobeUpsert, extField, false);
        insertErrors(divisionUpsert,'Division Portfolio Upsert');
        insertErrors(regionUpsert,'Region Portfolio Upsert');
        insertErrors(districtUpsert,'District Portfolio Upsert');
        insertErrors(collOpUpsert,'Collection Operation Portfolio Upsert');
        insertErrors(dmUpsert,'District Manager Portfolio Upsert');
        insertErrors(abmUpsert,'Area Booking Manager Portfolio Upsert');
        insertErrors(supUpsert,'Supervisor Portfolio Upsert');
        insertErrors(amUpsert,'Acount Manager Portfolio Upsert');
        insertErrors(nonGeoUpsert,'Other Non-Geo Portfolio Upsert');
    }
    public String createPortfolioRecord(Taxonomy__c taxoRecord1,String portCode, String portName,String parentKey,String keyValue, String portType,Map<String,BSF_Portfolio__c> portfolioMap, Set<String> portKeySet){
        BSF_Portfolio__c portfolio = new BSF_Portfolio__c();
        portfolio.Name  = portName;
        portfolio.Portfolio_Name__c = portName;
        portfolio.Portfolio_Code__c = portCode;
        portfolio.Portfolio_Type__c = portType;
        portfolio.Taxonomy_Type__c = taxoRecord1.RecordType.Name;
        portfolio.Territory_Portfolio__c = BSF_Utilities.isTerritoryPortfolio(taxoRecord1.RecordType.Name);
        portfolio.Account_Based_Portfolio__c = !BSF_Utilities.isTerritoryPortfolio(taxoRecord1.RecordType.Name);
        portfolio.Start_Date__c = taxoRecord1.Start_Date__c;
        portfolio.End_Date__c = taxoRecord1.End_Date__c;
        if(parentKey != null)
            portfolio.Parent_Portfolio__r = new BSF_Portfolio__c(External_Key__c=parentKey+'_'+taxoRecord1.Start_Date__c);
        keyValue = keyValue +'_'+portCode;
        portfolio.External_Key_BackEnd__c = keyValue;
        portfolio.External_Key__c = keyValue+'_'+taxoRecord1.Start_Date__c;
        portfolioMap.put(keyValue,portfolio);
        portKeySet.add(keyValue);
        system.debug('keyValue'+keyValue);
        return keyValue;
    }
    // 3807
    // Method to create record of Account Specialist
    public void createPortfolioRecordForAs(Taxonomy__c taxoRecord1,String portCode, String portName, String portType,Map<String,BSF_Portfolio__c> portfolioMap, Set<String> portKeySet){
        BSF_Portfolio__c portfolio = new BSF_Portfolio__c();
        portfolio.Name  = portName + ' AS';
        portfolio.Portfolio_Name__c = portName + ' AS';
        portfolio.Portfolio_Code__c = portCode;
        portfolio.Portfolio_Type__c = portType;
        portfolio.Taxonomy_Type__c = portType;
        portfolio.Territory_Portfolio__c = false;
        portfolio.Account_Based_Portfolio__c =true;
        portfolio.Parent_Portfolio__r = null;
        portfolio.Start_Date__c = taxoRecord1.Start_Date__c;
        portfolio.End_Date__c = taxoRecord1.End_Date__c;
        String keyValue = portType +'_'+portCode;
        portfolio.External_Key_BackEnd__c = keyValue;
        portfolio.External_Key__c = keyValue+'_'+taxoRecord1.Start_Date__c;
        portfolioMap.put(keyValue,portfolio);
        portKeySet.add(keyValue);
    }
    public void insertErrors(Database.UpsertResult[] upsertErrors,String errorDesc){
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        for(Database.UpsertResult result:upsertErrors){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
                errorList.add(BSF_Utilities.getErrorLog('Create Portfolio','BSFPortfolioHelper','createOrUpdatePortfolio','Error',errorDesc,result.getErrors()[0].getMessage()));
            }
        }
        if(errorList.size() > 0){
            Schema.DescribeSObjectResult ds = BSF_Error_Log__c.sObjectType.getDescribe();
            //if( ds.isCreateable() ){}
            Database.insert(errorList,false);
        }
    }
    public list<BSF_Portfolio__c> dmldecision(list<BSF_Portfolio__c> bsfList)
    {
        set<string> extKey = new set<string>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            extKey.add(bsf.External_Key_BackEnd__c);
            if(bsf.Parent_Portfolio__r.External_Key__c != null)
            {
                system.debug('parent'+bsf.Parent_Portfolio__r.External_Key__c.substringBeforeLast('_'));
                extKey.add(bsf.Parent_Portfolio__r.External_Key__c.substringBeforeLast('_'));
            }
        }
        list<BSF_Portfolio__c> existingBsfList = [select id,Name,External_Key__c,External_Key_BackEnd__c,Start_Date__c,End_Date__c,Parent_Portfolio__c,Parent_Portfolio__r.External_Key__c from BSF_Portfolio__c where External_Key_BackEnd__c IN:extKey order by CreatedDate desc];
        system.debug('existingBsfList'+existingBsfList);
        map<string,BSF_Portfolio__c> exKeyExBSfMap = new map<string,Bsf_Portfolio__c>();
        for(BSF_Portfolio__c bsf :existingBsfList)
        {
            if(!exKeyExBSfMap.keyset().contains(bsf.External_Key_BackEnd__c))
            {
                exKeyExBSfMap.put(bsf.External_Key_BackEnd__c,bsf);
            }
        }
        for(BSF_Portfolio__c bsf :bsfList)
        {
            string parentExtKey;
            if(bsf.Parent_Portfolio__r.External_Key__c != null)
                parentExtKey = bsf.Parent_Portfolio__r.External_Key__c.substringBeforeLast('_');
            if(exKeyExBSfMap != null && exKeyExBSfMap.get(bsf.External_Key_BackEnd__c) != null)
            {
                Bsf_Portfolio__c exBsfPortfolio = exKeyExBSfMap.get(bsf.External_Key_BackEnd__c);
                if(exKeyExBSfMap.keyset().contains(bsf.External_Key_BackEnd__c) && ((exBsfPortfolio.start_date__c != bsf.start_date__c &&
                                                                                     bsf.start_date__c <= exBsfPortfolio.End_date__c && bsf.start_date__c >= exBsfPortfolio.start_date__c) || bsf.start_date__c == exBsfPortfolio.End_date__c+1))
                {
                    system.debug('uijbj');
                    bsf.start_date__c = exBsfPortfolio.start_date__c;
                    bsf.External_Key__c = exBsfPortfolio.External_Key__c;
                    if(exBsfPortfolio.Parent_Portfolio__c!=null && exBsfPortfolio.Parent_Portfolio__r.External_Key__c != null)
                        bsf.Parent_Portfolio__r = new BSF_Portfolio__c(External_Key__c=exBsfPortfolio.Parent_Portfolio__r.External_Key__c);
                }
                else if(exKeyExBSfMap.keyset().contains(parentExtKey))
                {
                    system.debug('Its here');
                    BSF_Portfolio__c parentBSf = exKeyExBSfMap.get(parentExtKey);
                    bsf.Parent_Portfolio__r = new BSF_Portfolio__c(External_Key__c=parentBSf.External_Key__c);
                }
            }
            else if(exKeyExBSfMap.keyset().contains(parentExtKey))
            {
                system.debug('Its here');
                BSF_Portfolio__c parentBSf = exKeyExBSfMap.get(parentExtKey);
                bsf.Parent_Portfolio__r = new BSF_Portfolio__c(External_Key__c=parentBSf.External_Key__c);
            }
        }
        return bsfList;
    }
}