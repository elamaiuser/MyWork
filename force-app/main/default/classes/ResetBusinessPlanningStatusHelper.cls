global with sharing class ResetBusinessPlanningStatusHelper
{
    /*@InvocableMethod(label='Reset Business Plan Status')
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
        
    }*/

    global class Request {
        @InvocableVariable(required=true) global String action; 
        @InvocableVariable global String profileName;
        @InvocableVariable global Boolean onlyCompleted;
    }

    global class Response {
        @InvocableVariable global Integer total;
        @InvocableVariable global Id jobId;
    }

    @InvocableMethod(label='Reset Business Planning - Count or Start')
    global static List<Response> run(List<Request> requests) {
        Request r = requests[0];
        Response res = new Response();

        Boolean onlyCompleted = (r.onlyCompleted == null) ? true : r.onlyCompleted;
        String whereClause = onlyCompleted
            ? 'WHERE Business_Planning_Completed__c = TRUE'
            : 'WHERE Business_Planning_Completed__c = FALSE';

        if (r.action == 'count') {
            Integer total = (Integer)Database.countQuery('SELECT COUNT() FROM Account ' + whereClause);
            res.total = total;
        }
        else if (r.action == 'start') {
            String soql = 'SELECT Id, Business_Planning_Completed__c FROM Account ' + whereClause;

            Integer batchSize;
            for (Reset_Business_Planning_Setting__mdt m : Reset_Business_Planning_Setting__mdt.getAll().values()) {
                if (m.Allowed_Profiles__c == r.profileName) {
                    batchSize = (m.Batch_Size__c == null) ? null : Integer.valueOf(m.Batch_Size__c);
                    break;
                }
            }

            BSF_Batch_ResetBusinessPlanningStatus b = new BSF_Batch_ResetBusinessPlanningStatus(soql);
            res.jobId = (batchSize != null && batchSize > 0)
                ? Database.executeBatch(b, batchSize)
                : Database.executeBatch(b);
        }
        return new List<Response>{ res };
    }
}