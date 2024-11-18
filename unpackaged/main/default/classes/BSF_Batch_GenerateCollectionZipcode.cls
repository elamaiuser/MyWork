/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 05/15/2024                     Balaji N                   This batch is created part of HRP-12054
*
*/
global class BSF_Batch_GenerateCollectionZipcode implements Database.Batchable<SObject>,Database.Stateful
{
    global Decimal taxVer;
    global Date startDate;
    global Date endDate;
    global Set<Id> upsertedSiteCollectionOperationIds = new Set<Id>();
    global BSF_Batch_GenerateCollectionZipcode (Decimal taxVer,Date startDate,Date endDate)
    {
        this.taxVer=taxVer;
        this.startDate=startDate;
        this.endDate=endDate;
    }
    
    global database.querylocator start(Database.BatchableContext bc)
    {
        String query='SELECT Id, Collection_Operation_Name__c,Collection_Operation_Code__c, End_Date__c, Start_Date__c, Zip_Code__c,Time_Zone__c FROM Taxonomy__c WHERE RecordType.Name = \'Bio Collection BSF\' AND Version_Key__c = :taxVer order by Zip_Code__c';
        
        
        return Database.getqueryLocator(query);
    }
    
    global void Execute(Database.BatchableContext bc,List<Taxonomy__c> taxoList)
    {
        Set<String> externalKeySet = new Set<String>();
        Set<String> collectionOpCodeSet = new Set<String>();
        Set<String> zipCodeSet = new Set<String>();
        for(Taxonomy__c tx:taxoList)
        {
            externalKeySet.add('Bio_Collection_BSF_CollZip_'+tx.Zip_Code__c+'_'+tx.Collection_Operation_Code__c);
            collectionOpCodeSet.add(tx.Collection_Operation_Code__c);
            zipCodeSet.add(tx.Zip_Code__c);
        }
        
        Map<String,Id> CollZipRegionMap = BSF_Utilities.findSkedRegion(collectionOpCodeSet,zipCodeSet,taxoList,null,null,null);
        
        //Existing collZip
        List<Biomed_Collection_Op_Center__c> collectionOperationList =[SELECT Id, Name , Biomed_Collection_Op_Code_Center_ID__c FROM Biomed_Collection_Op_Center__c WHERE 
                                                                       Biomed_Collection_Op_Code_Center_ID__c IN :collectionOpCodeSet AND External_ID__c != NULL];
        Map<String, Biomed_Collection_Op_Center__c> collOpCodeMap = new Map<String, Biomed_Collection_Op_Center__c>();
        Set<Id> collIdSet = new Set<Id>();
        for (Biomed_Collection_Op_Center__c collOp : collectionOperationList) 
        {
            collOpCodeMap.put(collOp.Biomed_Collection_Op_Code_Center_ID__c, collOp);
            collIdSet.add(collOp.Id);
        }
        
        Map<String, Collections_Territory__c> extIdcollTerrMap = new Map<String, Collections_Territory__c>();
        List<Collections_Territory__c> collectionTerrList =[Select id,External_Id_BackEnd__c,External_Id__c,sked_Start_Date__c,sked_End_Date__c from Collections_Territory__c WHERE External_Id_BackEnd__c IN:externalKeySet AND sked_End_Date__c>=Today ORDER BY sked_Start_Date__c];
        for (Collections_Territory__c collTerr : collectionTerrList) 
        {
            system.debug('collTerr'+collTerr);
            extIdcollTerrMap.put(collTerr.External_Id_BackEnd__c, collTerr);
        }
        
        //Existing SiteCo 
        List<sked__Location__c> siteList = [SELECT Id, sked_Zip_Code__c, sked_Timezone__c FROM sked__Location__c WHERE sked_Zip_code__c IN :zipCodeSet];
        Map<Id,sked__Location__c> siteIdMap = new Map<Id,sked__Location__c>();
        system.debug('siteList'+siteList);
        for (sked__Location__c site : siteList) 
        {
            siteIdMap.put(site.Id,site);
        }
        List<sked_Site_Collection_Operation__c> existingSiteCOList=[SELECT Id, sked_Site__c, sked_End_Date__c, sked_Start_Date__c, sked_Collection_Operation__c, CreatedDate,sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,
                                                                    sked_Travel_Distance_1__c, sked_Travel_Distance_2__c,External_Id__c,External_Id_BackEnd__c FROM sked_Site_Collection_Operation__c WHERE sked_Site__c IN :siteIdMap.KeySet() AND sked_Start_Date__c != NULL
                                                                    AND sked_End_Date__c != NULL AND sked_End_Date__c>=Today ORDER BY sked_Start_Date__c ASC];
        
        Map<String, sked_Site_Collection_Operation__c> extIdSiteCollMap = new Map<String, sked_Site_Collection_Operation__c>();
        for (sked_Site_Collection_Operation__c SiteCo : existingSiteCOList) 
        {
            extIdSiteCollMap.put(SiteCo.External_Id_BackEnd__c, SiteCo);
        }
        
        
        
        //Upsert Lists
        Map<String,Collections_Territory__c> extIdCollectionZipUpsertListMap = new Map<String,Collections_Territory__c>();
        Map<String,sked_Site_Collection_Operation__c> extIdSiteCollZipUpsertListMap = new Map<String,sked_Site_Collection_Operation__c>();
        Map<String,Collections_Territory__c> zipCollZipMap = new Map<String,Collections_Territory__c>();
        Map<String,Taxonomy__c> zipTaxoMap = new Map<String,Taxonomy__c>();
        for(Taxonomy__c tx:taxoList)
        {
            string key='Bio_Collection_BSF_CollZip_'+tx.Zip_Code__c+'_'+tx.Collection_Operation_Code__c;
            Biomed_Collection_Op_Center__c collectionOperation = new Biomed_Collection_Op_Center__c();
            String collTerrExternalId;
            System.debug(key);
            //CollZip
            if (collOpCodeMap.containsKey(tx.Collection_Operation_Code__c)) 
            {
                collectionOperation = collOpCodeMap.get(tx.Collection_Operation_Code__c);
                Collections_Territory__c collTerr = new Collections_Territory__c();
                if(extIdcollTerrMap.containsKey(key)&& !(tx.Start_Date__c>extIdcollTerrMap.get(key).sked_End_Date__c+1))
                {
                    collTerr=extIdcollTerrMap.get(key);
                }
                else
                {
                    collTerr.Collection_Operation__c = collectionOperation.Id;
                    collTerr.Zip__c = tx.Zip_Code__c;
                    collTerr.sked_Start_Date__c = tx.Start_Date__c;
                    collTerr.sked_End_Date__c = tx.End_Date__c;
                    collTerr.External_Id_BackEnd__c=key;
                    collTerr.External_Id__c=key+'_'+tx.Start_Date__c;
                    extIdCollectionZipUpsertListMap.put('Bio_Collection_BSF_CollZip_'+tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c,collTerr);
                }
                zipCollZipMap.put(tx.Zip_Code__c,collTerr);
                zipTaxoMap.put(tx.Zip_Code__c,tx);
                //collTerrExternalId=collTerr.External_Id__c;
                //extIdCollectionZipUpsertListMap.put('Bio_Collection_BSF_CollZip_'+tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c,collTerr);
                System.debug('collTerrExternalId'+collTerrExternalId);
                System.debug('collTerr'+collTerr);
                
                
                /* //SiteCo
if(zipSitesMap.containsKey(tx.Zip_Code__c))
{
System.debug('Inside Site'+zipSitesMap.get(tx.Zip_Code__c));
System.debug('collTerrExternalId'+collTerrExternalId);
for(sked__Location__c site : zipSitesMap.get(tx.Zip_Code__c))
{
key='Bio_Collection_BSF_SiteCo_'+tx.Collection_Operation_Code__c+'_'+site.Id;
sked_Site_Collection_Operation__c newSiteCO = new sked_Site_Collection_Operation__c
(
sked_Collection_Operation__c = collectionOperation.Id,
sked_Site__c = site.Id,
sked_Collections_Zip_Code__r =new Collections_Territory__c(External_Id__c=collTerrExternalId),
sked_Start_Date__c = tx.Start_Date__c,
sked_End_Date__c = tx.End_Date__c,
External_Id_BackEnd__c=key,
External_Id__c=key+'_'+tx.Start_Date__c,
sked_Region__c = CollZipRegionMap.get(collectionOperation.Biomed_Collection_Op_Code_Center_ID__c+'_'+tx.Zip_Code__c)
);

if(!extIdSiteCollMap.containsKey(key)
|| (extIdSiteCollMap.containsKey(key) && newSiteCO.sked_Start_Date__c>extIdSiteCollMap.get(key).sked_End_Date__c+1))
{
extIdSiteCollZipUpsertListMap.put('Bio_Collection_BSF_SiteCo_'+tx.Collection_Operation_Code__c+'_'+site.Id,newSiteCO);
}

}
}*/
            }
        }
        
        for(sked__Location__c site : siteList)
        {
            if(zipTaxoMap.containsKey(site.sked_Zip_Code__c))
            {
                
                Taxonomy__c tx=zipTaxoMap.get(site.sked_Zip_Code__c);
                if(collOpCodeMap.containsKey(tx.Collection_Operation_Code__c) && zipCollZipMap.containsKey(site.sked_Zip_Code__c))
                {
                    Biomed_Collection_Op_Center__c collectionOperation = collOpCodeMap.get(tx.Collection_Operation_Code__c);
                    Collections_Territory__c collTerr=zipCollZipMap.get(site.sked_Zip_Code__c);
                    String key='Bio_Collection_BSF_SiteCo_'+tx.Collection_Operation_Code__c+'_'+site.Id;
                    sked_Site_Collection_Operation__c newSiteCO = new sked_Site_Collection_Operation__c
                        (
                            sked_Collection_Operation__c = collectionOperation.Id,
                            sked_Site__c = site.Id,
                            sked_Collections_Zip_Code__r =new Collections_Territory__c(External_Id__c=collTerr.External_Id__c),
                            sked_Start_Date__c = tx.Start_Date__c,
                            sked_End_Date__c = tx.End_Date__c,
                            External_Id_BackEnd__c=key,
                            External_Id__c=key+'_'+tx.Start_Date__c,
                            sked_Region__c = CollZipRegionMap.get(collectionOperation.Biomed_Collection_Op_Code_Center_ID__c+'_'+tx.Zip_Code__c)
                        );
                    
                    if(!extIdSiteCollMap.containsKey(key)
                       || (extIdSiteCollMap.containsKey(key) && newSiteCO.sked_Start_Date__c>extIdSiteCollMap.get(key).sked_End_Date__c+1))
                    {
                        extIdSiteCollZipUpsertListMap.put('Bio_Collection_BSF_SiteCo_'+tx.Collection_Operation_Code__c+'_'+site.Id,newSiteCO);
                    }
                }
                
                
            }
            
        }
        List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
        logList.addAll(BSF_Utilities.createErrorLog(Database.upsert(extIdCollectionZipUpsertListMap.values(), Collections_Territory__c.External_Id__c, false), 'Generate Coll Zip','BSF_Batch_GenerateCollectionZipcode','Execute','Error','Error during Coll Zip Upsert'));
        logList.addAll(BSF_Utilities.createErrorLog(Database.upsert(extIdSiteCollZipUpsertListMap.values(), sked_Site_Collection_Operation__c.External_Id__c, false), 'Generate Coll Zip','BSF_Batch_GenerateCollectionZipcode','Execute','Error','Error during Coll Zip Upsert'));
        
        InsertBsfErrorLog.insertBsfErrors(logList);
        
        
        for(sked_Site_Collection_Operation__c siteCo:extIdSiteCollZipUpsertListMap.values())
        {
            this.upsertedSiteCollectionOperationIds.add(siteCo.Id);
        }
    }
    
    global void Finish(Database.BatchableContext bc)
    {
        BSF_Batch_EndCollectionZip batch = new BSF_Batch_EndCollectionZip(taxVer,this.upsertedSiteCollectionOperationIds);
        Database.executeBatch(batch,50);
    }
    
}