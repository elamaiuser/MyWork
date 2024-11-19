/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 06/18/2024                     Balaji N                   This batch is created part of HRP-12054
*
*/
Global class BSF_Batch_CollectionZipOneTime implements Database.Batchable<SObject>
{
    Public Boolean collectionZip=false;
    Public Boolean siteCo=false;
    Global BSF_Batch_CollectionZipOneTime(Boolean collectionZip,Boolean siteCo)
    {
        if(collectionZip)
        {
            this.collectionZip=true;
        }
        if(siteCo)
        {
            this.siteCo=true;
        }
    }
    Global Database.QueryLocator Start(Database.BatchableContext bc)
    {
        String query;
        if(this.collectionZip)
        {
           query='select id,External_Id_BackEnd__c,External_Id__c,Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c,Zip__c,sked_Start_Date__c,sked_End_Date__c from Collections_Territory__c where (External_Id_BackEnd__c=null OR External_Id__c=null) AND sked_Start_Date__c!=null AND sked_End_Date__c!=null';
        }
        if(this.siteCo)
        {
            query='select id,External_Id_BackEnd__c,External_Id__c,sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c,sked_Start_Date__c,sked_Site__c from sked_Site_Collection_Operation__c where (External_Id_BackEnd__c=null OR External_Id__c=null) AND sked_Start_Date__c!=null AND sked_End_Date__c!=null';
        }
         system.debug('query'+query);
        return Database.getqueryLocator(query);
    }
    global void Execute(DataBase.BatchableContext bc,List<SObject> sobjectList)
    {
        skedHubBase.BypassUpdateTriggers=true;
        if(this.collectionZip)
        {
            List<Collections_Territory__c> collTerrList =(List<Collections_Territory__c>) sobjectList;
        
        for(Collections_Territory__c collTerr:collTerrList)
        {
            collTerr.External_Id_BackEnd__c='Bio_Collection_BSF_CollZip_'+collTerr.Zip__c+'_'+collTerr.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c;
            collTerr.External_Id__c='Bio_Collection_BSF_CollZip_'+collTerr.Zip__c+'_'+collTerr.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+collTerr.sked_Start_Date__c;
        }
        
        Database.Update(collTerrList,false);
           
        }
        else if(this.siteCo)
        {
            List<sked_Site_Collection_Operation__c> SiteCoList=(List<sked_Site_Collection_Operation__c>) sobjectList;
        
        for(sked_Site_Collection_Operation__c SiteCo:SiteCoList)
        {
            SiteCo.External_Id_BackEnd__c='Bio_Collection_BSF_SiteCo_'+SiteCo.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+SiteCo.sked_Site__c;
            SiteCo.External_Id__c='Bio_Collection_BSF_SiteCo_'+SiteCo.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+SiteCo.sked_Site__c+'_'+SiteCo.sked_Start_Date__c;
        }
        TriggerHandler.Bypass('SiteCollectionOperationTriggerHandler');
        Database.Update(SiteCoList,false);
        TriggerHandler.clearAllBypasses(); 
        }
        skedHubBase.BypassUpdateTriggers=false;    
    }
    
    global void Finish(Database.BatchableContext bc)
    {
    }
}