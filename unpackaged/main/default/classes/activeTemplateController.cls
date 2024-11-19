/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  10/02/2024				 Kishore Das		        Logic for HRP-11728(Template Drive Keyword default to Sponsor Keyword on Creation)

 *************************************************************************************************************************************************************************************
*/
public class activeTemplateController {
    @AuraEnabled(cacheable=true)
    public Static list<opportunity> getActiveTemplates(Id accountIds){
        //system.debug('accountId '+accountIds);
        list<Opportunity> oppList = [select Id, name,accountId,Template_Status__c,Drive_Keyword__c,Account.Sponsor_Keyword__c 
                                     from opportunity where Template_Status__c = 'Active' AND Is_Template__C=true
                                     and accountId =:accountIds]; 
        //system.debug('oppList## '+oppList);
        return oppList;    
    }
    @AuraEnabled
    public Static void updateFutureOpportunities(List<Id> templateIds){ 
        //system.debug('templateIds '+templateIds);
        List<Opportunity> templates =[select Id, name,accountId,Template_Status__c,Drive_Keyword__c 
                                     from opportunity where Template_Status__c = 'Active' AND Is_Template__C=true
                                     and Id =:templateIds];
        String SponsorKeyword;
        
        set<Id> accountIds = new set<Id>();
        for(opportunity op:templates){
            accountIds.add(op.accountId);
        }
        SponsorKeyword =[select Sponsor_Keyword__c from account where id in:accountIds].Sponsor_Keyword__c;
        for(opportunity op:templates){
            op.Drive_Keyword__c=SponsorKeyword;
        }
        update templates;
        Database.saveResult[] updateList = Database.update(templates, false);
        List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(updateList, 'UpdateSponsorkeyword', 'activeTemplateController', 'updateFutureOpportunities', 'Error', 'Error updating sponsor keyword for templates');
        Insert errorLogList;
        
        List<String> successfulTemplateIds = new List<String>();
        for (Database.SaveResult sr : updateList) {
            if (sr.isSuccess()) {
                successfulTemplateIds.add(sr.getId());
            }
        }
        
         if (!successfulTemplateIds.isEmpty()) {
            FutureOpportunityUpdate__e event = new FutureOpportunityUpdate__e();
            event.TemplateIds__c = String.join(successfulTemplateIds, ',');
            Database.SaveResult eventSaveResult = EventBus.publish(event);
        }
    }
}