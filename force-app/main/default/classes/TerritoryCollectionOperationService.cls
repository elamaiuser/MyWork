public class TerritoryCollectionOperationService 
{
	Public static void DateHandlingOnUpdate(map<id,sked_Territory_Collection_Operation__c>oldmap,List<sked_Territory_Collection_Operation__c> newItems)
    {
        for(sked_Territory_Collection_Operation__c tcp : newItems)
        {
            if(tcp.sked_Start_Date__c != oldmap.get(tcp.id).sked_Start_Date__c 
               && tcp.sked_Start_Date__c < oldmap.get(tcp.id).sked_End_Date__c)
            {
                tcp.sked_Start_Date__c = oldmap.get(tcp.id).sked_Start_Date__c;
            system.debug(tcp.sked_Start_Date__c);
            }
            /*if(tcp.sked_End_Date__c != oldmap.get(tcp.id).sked_End_Date__c)
            {
                tcp.sked_End_Date__c = oldmap.get(tcp.id).sked_End_Date__c;
            }*/
        }
    }
}