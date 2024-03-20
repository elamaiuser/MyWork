public class TerritoryService 
{
	public static void updateTerritoryCollOp(List<sked_Territory__c>newItems,map<id,sked_Territory__c>oldMap)
    {
        set<string> terrExIdSet = new set<string>();
        map<string,sked_Territory__c> exIdTerrMap = new map<string,sked_Territory__c>();
        for(sked_Territory__c terr : newItems)
        {
            if(oldMap.get(terr.id).End_Date__c != terr.End_Date__c)
            {
            terrExIdSet.add(terr.External_Id__c);
            exIdTerrMap.put(terr.External_Id__c,terr);
            }
        }
        
        
        list<sked_Territory_Collection_Operation__c> relatedTerritoryCollOpList = [select id,sked_Start_Date__c,sked_End_Date__c,sked_External_ID__c,
                                                                                   sked_Territory__c,sked_Territory__r.External_Id__c from sked_Territory_Collection_Operation__c where sked_Territory__r.External_Id__c IN:terrExIdSet];
        system.debug('relatedTerritoryCollOpList'+relatedTerritoryCollOpList);
        list<sked_Territory_Collection_Operation__c> relatedTerritoryCollOpListToUpdate = new list<sked_Territory_Collection_Operation__c>();
        for(sked_Territory_Collection_Operation__c terCollOp:relatedTerritoryCollOpList)
        {
            terCollOp.sked_End_Date__c = exIdTerrMap.get(terCollOp.sked_Territory__r.External_Id__c).End_Date__c;
            relatedTerritoryCollOpListToUpdate.add(terCollOp);
        }
        
        if(!relatedTerritoryCollOpListToUpdate.isEmpty())
        {
            Database.update(relatedTerritoryCollOpListToUpdate,false);
        }
    }
}