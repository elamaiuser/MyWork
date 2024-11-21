/**
 * @description: This apex class is executed from flow(Initiate Marketing Exception Request) to update future opportunities.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 10/28/2023			    Kishore Das 			Logic for HRP-10929(Marketing Exception Enhancement)
 * *****************************************************************************************************************************************************************************************
 **/

public class updateOpportunitiesInvocable {
	@InvocableMethod(label='update opportunities')
    public static void updateBloodDriveFromFlow(List<Id> Opp){
        Map<Id,opportunity> opptyMap = new Map<Id,opportunity>([select id,
                                                                		is_template__c,
                                                                		Parent_Template_Id__c ,
                                                                		Publish_to_Call_Center__c,
                                                                		Send_Emails__c,Send_Mailers__c,
                                                                		Web_Scheduling_Enabled__c 
                                                                	from opportunity 
                                                                	where Is_Template__c = true 
                                                                	AND id IN: Opp]);
        if(opptyMap.isEmpty()){
            return;
        }
        list<opportunity> futureoOpplist=[select id,is_template__c,Parent_Template_Id__c ,Publish_to_Call_Center__c,Send_Emails__c,Send_Mailers__c,Web_Scheduling_Enabled__c
                                           from opportunity where Parent_Template_Id__c IN: opptyMap.keySet() and Drive_date__c > :system.today()];
        system.debug('futureoOpplist##'+futureoOpplist);
		for(opportunity op:futureoOpplist){
            op.Publish_to_Call_Center__c = opptyMap.get(op.Parent_Template_Id__c).Publish_to_Call_Center__c;
            op.Send_Emails__c = opptyMap.get(op.Parent_Template_Id__c).Send_Emails__c;
            op.Send_Mailers__c = opptyMap.get(op.Parent_Template_Id__c).Send_Mailers__c;
            op.Web_Scheduling_Enabled__c = opptyMap.get(op.Parent_Template_Id__c).Web_Scheduling_Enabled__c;
        }
         if(!futureoOpplist.isEmpty())
        {
            try
            {
                Database.SaveResult[] srList = Database.update(futureoOpplist,false);
                for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully updated opportunity: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    }
                }
            }
            }
            catch(exception e)
            {
                system.debug('The Error in updating opportunity  : '+e);
            }
        }
    }
}