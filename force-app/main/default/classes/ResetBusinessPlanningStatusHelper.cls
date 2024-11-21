global with sharing class ResetBusinessPlanningStatusHelper
{
    @InvocableMethod(label='Reset Business Plan Status')
    global static void runBusinessPlanResetBatch(List<getValues> listOfValues)
    {
        Integer batchSize;
        List<Reset_Business_Planning_Setting__mdt> resetBusinessPlanMetadata = Reset_Business_Planning_Setting__mdt.getAll().values();
        for(getValues val : listOfValues)
        {
            for(Reset_Business_Planning_Setting__mdt value : resetBusinessPlanMetadata)
            {
                if(value.Allowed_Profiles__c.equals(val.profileName))
                {
                    batchSize = Integer.valueOf(value.Batch_Size__c);
                    break;
                }
            }            
        }
        
        
        BSF_Batch_ResetBusinessPlanningStatus batch = new BSF_Batch_ResetBusinessPlanningStatus(listOfValues);
        Database.executeBatch(batch, batchSize);        
          
    }
    
    global class getValues
    {
        @InvocableVariable
        global List<Account> accListToBeUpdated;
        
        @InvocableVariable
        global String profileName;
        
    }

}