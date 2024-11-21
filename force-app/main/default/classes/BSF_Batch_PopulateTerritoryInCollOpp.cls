global class BSF_Batch_PopulateTerritoryInCollOpp implements Database.Batchable<sObject>
{
    
    public  boolean isAll;
    global BSF_Batch_PopulateTerritoryInCollOpp(boolean isAll)
    {
        this.isAll = isAll;
    }
    
    global BSF_Batch_PopulateTerritoryInCollOpp()
    {
        this.isAll=false;
    }
	global List<sked_Territory_Collection_Operation__c> start(Database.BatchableContext bc)
    {
        List<sked_Territory_Collection_Operation__c> terrCollOppList = new List<sked_Territory_Collection_Operation__c> ();
        if(!isAll)
        {
            terrCollOppList = [select Id,sked_Collection_Operation__c,sked_Territory__c,sked_Start_Date__c,sked_End_Date__c from sked_Territory_Collection_Operation__c 
            																where sked_Start_Date__c = Yesterday or sked_Start_Date__c = Today];
        }
        else
        {
            terrCollOppList = [select Id,sked_Collection_Operation__c,sked_Territory__c,sked_Start_Date__c,sked_End_Date__c from sked_Territory_Collection_Operation__c 
            																where sked_End_Date__c >= Today];
        }
        
        system.debug(terrCollOppList);
        return terrCollOppList; 
    }
    
    
    global void execute(Database.BatchableContext bc, List<sked_Territory_Collection_Operation__c> terrCollOppList)
    {
        set<id> collOpIdset = new set<id>();
        for(sked_Territory_Collection_Operation__c tc:terrCollOppList)
        {
            collOpIdset.add(tc.sked_Collection_Operation__c);
        }
        
        map<id,Biomed_Collection_Op_Center__c> collOpMap = new map<id,Biomed_Collection_Op_Center__c>([select id,sked_Territory__c from Biomed_Collection_Op_Center__c where id In:collOpIdset]);
        list<Biomed_Collection_Op_Center__c> collOpUpdateList = new list<Biomed_Collection_Op_Center__c>();
        for(sked_Territory_Collection_Operation__c tc:terrCollOppList)
        {
            Biomed_Collection_Op_Center__c collOp = collOpMap.get(tc.sked_Collection_Operation__c);
            if(tc.sked_Start_Date__c <= system.today() && tc.sked_End_Date__c >= system.today()
              && collOp.sked_Territory__c != tc.sked_Territory__c)
            {
                collOp.sked_Territory__c = tc.sked_Territory__c;
                collOpUpdateList.add(collOp);
            }
        }
        
        if(!collOpUpdateList.isEmpty())
        {
            Database.update(collOpUpdateList,false);
        }
    }
    
    global void finish(Database.BatchableContext bc)
    {
        system.debug('BSF_Batch_PopulateTerritoryInCollOpp ran successfully');
    }
    
}