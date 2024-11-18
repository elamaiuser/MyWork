/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 05/15/2024                     Balaji N                   This batch is created part of HRP-12054
*
*/
global class BSF_Batch_EndCollectionZip implements Database.Batchable<SObject>,Database.Stateful
{
    global Decimal taxVer;
    global Date startDate;
    global Date endDate;
    global Decimal oldTaxVersionKey;
    global Date oldEndDate;
    global Set<Id> upsertedSiteCollectionOperationIds = new Set<Id>();
    global Set<Id> indexIds = new Set<Id>();
    global BSF_Batch_EndCollectionZip (Decimal taxVer,Set<Id>upsertedSiteCollectionOperationIdsFromGenerateBatch)
    {
        this.upsertedSiteCollectionOperationIds.addAll(upsertedSiteCollectionOperationIdsFromGenerateBatch);
        this.taxVer=taxVer;
        this.startDate=startDate;
        this.endDate=endDate;
    }
    
    global Database.QueryLocator Start (Database.BatchableContext bc)
    {
        String query='SELECT Id, Collection_Operation_Name__c,Collection_Operation_Code__c, End_Date__c, Start_Date__c, Zip_Code__c,Version_Key__c FROM Taxonomy__c WHERE RecordType.Name = \'Bio Collection BSF\' AND Version_Key__c != :taxVer order by Zip_Code__c,Version_Key__c desc';
        
        return Database.getqueryLocator(query);
    }
    
    global void Execute(DataBase.BatchableContext bc,List<Taxonomy__c> taxoList)
    {
        if(oldTaxVersionKey == null)
        {
            list<Taxonomy__c> txList = [select id,Version_Key__c,End_Date__c from Taxonomy__c where RecordType.Name ='Bio Collection BSF' AND Version_Key__c != :taxVer order by Version_Key__c desc limit 1];
            oldTaxVersionKey =txList[0].Version_Key__c;
            oldEndDate=txList[0].End_Date__c;
            System.debug('oldTaxVersionKey'+oldTaxVersionKey+':'+'oldEndDate'+oldEndDate);
        }
        
        Set<String> oldExternalKeySet = new Set<String>();
        Set<String> oldZipCodeSet = new Set<String>();
        for(Taxonomy__c tx:taxoList)
        {
            if(tx.Version_Key__c==oldTaxVersionKey)
            {
                oldExternalKeySet.add('Bio_Collection_BSF_CollZip_'+tx.Zip_Code__c+'_'+tx.Collection_Operation_Code__c);
                oldZipCodeSet.add(tx.Zip_Code__c);
            }
            
        }
        
        List<Taxonomy__c> newVersionTaxList = new List<Taxonomy__c> ();
        newVersionTaxList = [SELECT Id, Collection_Operation_Name__c,Collection_Operation_Code__c, End_Date__c, Start_Date__c, Zip_Code__c FROM Taxonomy__c WHERE RecordType.Name = 'Bio Collection BSF' AND Version_Key__c = :taxVer AND Zip_Code__c IN:oldZipCodeSet order by Zip_Code__c];
        Set<String> newExternalKeySet = new Set<String>();
        Set<String> newwZipCodeSet = new Set<String>();
        for(Taxonomy__c tx:newVersionTaxList)
        {
            newExternalKeySet.add('Bio_Collection_BSF_CollZip_'+tx.Zip_Code__c+'_'+tx.Collection_Operation_Code__c);
        }
        
        Set<String> endedExtIdSet = new Set<String>();
        for(String s :oldExternalKeySet)
        {
            if(!newExternalKeySet.contains(s))
            {
                endedExtIdSet.add(s);
            }
        }
        
        List<Collections_Territory__c> collZipToEndList = [Select Id,sked_Start_Date__c,sked_End_Date__c,External_Id__c from Collections_Territory__c where External_Id_BackEnd__c IN:endedExtIdSet AND sked_End_Date__c>=Today];
        Set<String> endedExternalIdSet = new Set<String>();
        for(Collections_Territory__c collZip : collZipToEndList)
        {
            collZip.sked_End_Date__c=oldEndDate;
            endedExternalIdSet.add(collZip.External_Id__c);
            system.debug('collZip '+collZip);
            
        }
        
        Database.Update(collZipToEndList,false);
        
        List<sked_Site_Collection_Operation__c> existingSiteCOList=[SELECT Id, sked_Site__c, sked_End_Date__c, sked_Start_Date__c, sked_Collection_Operation__c, CreatedDate,sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,
                                                                    sked_Travel_Distance_1__c, sked_Travel_Distance_2__c,External_Id__c,External_Id_BackEnd__c,sked_Collections_Zip_Code__c FROM sked_Site_Collection_Operation__c WHERE sked_Collections_Zip_Code__r.External_Id__c IN:endedExternalIdSet AND sked_Start_Date__c != NULL
                                                                    AND sked_End_Date__c != NULL AND sked_End_Date__c>=Today ORDER BY sked_Start_Date__c ASC];
        
        for(sked_Site_Collection_Operation__c siteCo :existingSiteCOList)
        {
            siteCo.sked_End_Date__c=oldEndDate;
            upsertedSiteCollectionOperationIds.add(siteCo.id);
        }
        
        Database.Update(existingSiteCOList,false);
    }
    
    global void Finish(Database.BatchableContext bc)
    {
        if(!test.isRunningTest())
        {
            system.debug('this.upsertedSiteCollectionOperationIds '+this.upsertedSiteCollectionOperationIds);
            if(!this.upsertedSiteCollectionOperationIds.isempty())
            {
                
                Database.executeBatch(new skedDriveCOChangedBatch(this.upsertedSiteCollectionOperationIds), 200);
            }
            
            List<sked_Travel_Time_Index_Item__c> travelTimeIdList=[SELECT Id FROM sked_Travel_Time_Index_Item__c
                                                                   WHERE  sked_Last_Refresh_Date__c=null] ;
            List<Id> indexIdsList = new List<Id>();
            
            if(!travelTimeIdList.isempty())
            {
                for(sked_Travel_Time_Index_Item__c  tr:travelTimeIdList)
                {
                    indexIdsList.add(tr.Id);
                }
                Database.executeBatch(new skedImmediateRefreshTravelTimeIndexBatch(indexIdsList, skedSetting.instance.TravelTime.newIndexPriority), 200);
            }
        }
    }
}