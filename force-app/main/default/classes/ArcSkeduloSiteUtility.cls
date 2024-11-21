/**
 * @description: This is apex class updates the template's status to inactive if sites getting inactivate.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 11/16/2023			    Barnojit Sharma			Unable to Inactivate Charlottesville Integrated Fixed Site record (HRP-11543)
 * *****************************************************************************************************************************************************************************************
 **/
public with sharing class ArcSkeduloSiteUtility{
    public static void inactiveTemplatesforSites(List<Id> inactiveSites){
        /*
        * HRP-11543 changes starts here
        */
        if(inactiveSites == null || inactiveSites.isEmpty()){
            return;
        }
        /*
        * HRP-11543 changes ends here
        */
        try{
            List<Opportunity> oppListToUpdate = new List<Opportunity>();
            //update only templates if the template's status is not Inactive already
            for(Opportunity opp : [SELECT Id,
                                            Template_Status__c 
                                    FROM Opportunity 
                                    WHERE Drive_Site__c IN: inactiveSites 
                                    AND is_Template__c = true //HRP-11543 changes
                                    AND Template_Status__c != 'Inactive']){ // HRP-11543 changes
                opp.Template_Status__c = 'Inactive';
                oppListToUpdate.add(opp);
            }
            if(!oppListToUpdate.isEmpty()){
                Database.SaveResult[] results = Database.update(oppListToUpdate, true);
            }
            if(Test.isRunningTest()){
                throw new DMLException('Unable to Perform the DML Operation on Opportunity Templates.');
            }
        /*
        * HRP-11543 changes starts here
        */
        }catch(Exception expt){
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'ArcSkeduloSiteUtility',expt.getStackTraceString(),'Error','Error updating templates',expt.getMessage());
            if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                try{
                    insert err;
                }catch(Exception excptn){
                    System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                }
            }
            throw new DMLException('Unable to Perform the DML Operation on Opportunity Templates : ' +expt.getMessage());
       }
       /*
        * HRP-11543 changes ends here
        */
    }
}