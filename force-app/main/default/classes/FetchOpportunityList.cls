public with sharing class FetchOpportunityList{
    @AuraEnabled(cacheable = true)
    public static List<opportunity> listOppLwc(){
        return [SELECT Id,Name,Account.Name, Drive_Date__c,Description FROM opportunity  limit 50 ];
    }
    @AuraEnabled(cacheable = false)
    public static List<opportunity> updateOppLwc(List<Opportunity> oppListToUpdate){
        try{
           // Schema.DescribeSObjectResult ds = Opportunity.sObjectType.getDescribe();
           // if( ds.isUpdateable() ){}
                update(oppListToUpdate);
            
        }
        catch (Exception e) {
            //System.debug('unable to update the record due to'+e.getMessage());
        }
        return oppListToUpdate;
    }
}