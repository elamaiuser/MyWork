/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *************************************************************************** 
 * 6/22/2023					  Ankit Kundu			 Logic for HRP-6231 
 * 
 *****************************************************************************
*/


public class MassUpdateOpportunityBatch implements Database.Batchable<MassUpdateOpportunity.oppVariable>, Database.Stateful{
    public List<MassUpdateOpportunity.oppVariable> oppIdList;
    public Map<Id, String> dml_error_map = new Map<Id, String>();
    public Map<Exception,String> common_exception_map = new Map<Exception,String>();
    public MassUpdateOpportunityBatch(List<MassUpdateOpportunity.oppVariable> oppIds) {
        this.oppIdList = new List<MassUpdateOpportunity.oppVariable>();
        this.oppIdList=oppIds;
    }
    public Iterable<MassUpdateOpportunity.oppVariable> start(Database.BatchableContext BC){
        return this.oppIdList;
    }
    public void execute(Database.BatchableContext bc, List<object> scope){
        try{
            List<MassUpdateOpportunity.oppVariable> oppIds = (List<MassUpdateOpportunity.oppVariable>)scope;
            system.debug('======execute method-scope--'+ oppIds);
            List<Opportunity> oppToUpdate = new List<Opportunity>();
            oppToUpdate = oppIds.get(0).oppToUpdate;
            
            List<Opportunity> storeOppValues = new List<Opportunity>();
            if(oppToUpdate != null){
                for(Opportunity opp : oppToUpdate){
                    try{
                        Opportunity op = new Opportunity();
                        op.Id = opp.Id;
                        
                        if(oppIds[0].updatedPlateletAsset != null && oppIds[0].updatedPlateletAsset >= 0){
                            op.Number_of_Platelet_Assets__c = oppIds[0].updatedPlateletAsset;
                        }if(oppIds[0].updatedPlasmaAsset != null  && oppIds[0].updatedPlasmaAsset >= 0){
                            op.Number_of_Plasma_Assets__c = oppIds[0].updatedPlasmaAsset;
                        }if(oppIds[0].updated2rbcAsset != null  && oppIds[0].updated2rbcAsset >= 0){
                            op.Number_of_2RBC_Assets__c = oppIds[0].updated2rbcAsset;
                        }if(oppIds[0].updatedCalendarDesc != null && oppIds[0].updatedCalendarDesc != ''){
                            op.Calendar_Description__c = oppIds[0].updatedCalendarDesc;
                        }if(oppIds[0].updatedOnlineDonor != null && oppIds[0].updatedOnlineDonor != ''){
                            op.Online_Donor_Message__c = oppIds[0].updatedOnlineDonor;
                        }if(oppIds[0].updatedOpenToPublic != null && oppIds[0].updatedOpenToPublic != ''){
                            op.Open_to_Public__c = oppIds[0].updatedOpenToPublic;
                        }if(oppIds[0].updatedStage != null && oppIds[0].updatedStage != 'Cancelled'){
                            op.StageName = oppIds[0].updatedStage;
                        }else if(oppIds[0].updatedCancelledStage != null &&  oppIds[0].updatedCancellationReason != null && oppIds[0].updatedCancellationReason != ''){
                            op.StageName = oppIds[0].updatedCancelledStage;
                            op.sked_Cancellation_Reason__c = oppIds[0].updatedCancellationReason;
                            op.Initiated_By__c = oppIds[0].updatedInitiatedBy;
                        }if(oppIds[0].updatedPlateletPP != null && oppIds[0].updatedPlateletPP >= 0){
                            op.Platelet_Projected_Procedures__c = oppIds[0].updatedPlateletPP;
                        }                     
                        if(oppIds[0].updatedPlasmaPheresisPP != null && oppIds[0].updatedPlasmaPheresisPP >= 0){
                            op.Plasma_Pheresis_Projected_Procedures__c = oppIds[0].updatedPlasmaPheresisPP;
                        }
                        /*Add it for HRP-6231 [Start ->>]*/
                        if(oppIds[0].updatedAnticipatedRegisteredDonors != null && oppIds[0].updatedAnticipatedRegisteredDonors >= 0)
                        { 
                            if(oppIds[0].updatedARegisteredDonorsReason != null && oppIds[0].updatedARegisteredDonorsReason != ''){
                                op.Anticipated_Registered_Donors__c = oppIds[0].updatedAnticipatedRegisteredDonors;                         
                            op.AnticipatedRegisterDonorChangeReason__c = oppIds[0].updatedARegisteredDonorsReason;
                            }
                        }
                        
						/*[<<- End]*/ 
                        if(oppIds[0].updatedWBProjectedProc != null && oppIds[0].updatedWBProjectedProc >= 0){
                            if(oppIds[0].updatedWBProcReason != null && oppIds[0].updatedWBProcReason != ''){
                                op.WB_Projected_Procedures__c = oppIds[0].updatedWBProjectedProc;
                                op.WholeBloodProcedureProjectedChangeReason__c = oppIds[0].updatedWBProcReason;
                            }    
                        }if(oppIds[0].updated2RBCProjProcedure != null && oppIds[0].updated2RBCProjProcedure >= 0){
                            if(oppIds[0].updatedDRReason != null && oppIds[0].updatedDRReason != ''){
                                op.X2RBC_Projected_Procedures__c = oppIds[0].updated2RBCProjProcedure;
                                op.DoubleRedProceduresProjectedChangeReason__c = oppIds[0].updatedDRReason;
                            }   
                        }if(oppIds[0].updatedStartTime != null && oppIds[0].updatedStartTime != ''){
                            String strTimeSplit = oppIds[0].updatedStartTime.substring(0, 2);                    
                            String endTimeSplit = oppIds[0].updatedStartTime.substring(2);  
                            Time sTime = Time.newInstance(Integer.valueOf(strTimeSplit) //hour
                                                        ,Integer.valueOf(endTimeSplit) //min
                                                        ,0                                //sec
                                                        ,0);
                            op.Start_Time__c = sTime;
                        }if(oppIds[0].updatedEndTime != null && oppIds[0].updatedEndTime != ''){
                            String strSTimeSplit = oppIds[0].updatedEndTime.substring(0, 2);                    
                            String strETimeSplit = oppIds[0].updatedEndTime.substring(2);  
                            Date endDate = Date.newInstance(2000, 01, 01);
                            Time eTime = Time.newInstance(Integer.valueOf(strSTimeSplit) //hour
                                                        ,Integer.valueOf(strETimeSplit) //min
                                                        ,0                                //sec
                                                        ,1);
                            op.End_Time__c = eTime;
                        }else{
                            system.debug('--------------error----------------');
                        }
                        op.Processing_Status__c = 'Mass Update Not Processed';
                        System.debug(op);
                        storeOppValues.add(op);
                    }catch(Exception exp){
                        common_exception_map.put(exp,opp.Id);
                        continue;
                    }
                }        
            }   
            Database.SaveResult[] srList = Database.update(storeOppValues, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully created Opp ID: ' + sr.getId());
                }
                else {
                    for(Database.Error err : sr.getErrors()) {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    } 
                }
            }
        }catch(Exception ex){
            common_exception_map.put(ex,'');
        }
    }
    public void finish (Database.BatchableContext bc){
        
    }
}