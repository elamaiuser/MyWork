/* 
 * @description: This Scheduler class is created to Reset Portfolio Assignment flag and record count.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 12/26/2023				 Barnojit Sharma		     Reset Portfolio Assignment flag and record count(Logic for HRP-10460)
 ************************************************************************************************************************************************
*/
public without sharing class BSF_ResetPortfolioAssignmentJob implements Schedulable {
    public void execute(SchedulableContext context) {
        resetPortfolioAssignmentFlag();
    }
    public static void resetPortfolioAssignmentFlag(){
        try{
            Boolean resetFlag = false;
            Integer runningJobCount = 0;
            List<Portfolio_Accounts_Processing__c> accProcList = [SELECT Id,
                                                                        Portfolio_Assignment_Updated__c,
                                                                        Portfolio_progress_for_Accounts__c,
                                                                        Records_Processed__c,
                                                                        LastModifiedDate
                                                                    FROM Portfolio_Accounts_Processing__c
                                                                    LIMIT 1];
            if(!accProcList.isEmpty()){
                if(String.isNotBlank(System.label.PortfolioAssignmentBatchNames)){
                    List<String> portfolioAssignmentBatches = System.label.PortfolioAssignmentBatchNames.split(',');
                    List<String> batch_Status = Custom_Messages__mdt.getInstance('BSF_BatchProcessingStatuses').value__c.split(',');
                    runningJobCount = [SELECT Count() 
                                        FROM AsyncApexJob 
                                        WHERE ApexClass.Name IN: portfolioAssignmentBatches
                                        AND Status IN: batch_Status];
                }
                if(Test.isRunningTest() || (runningJobCount == 0 && accProcList.get(0).LastModifiedDate < Datetime.now().addMinutes(Integer.valueOf(System.label.ResetPortfolioAssignmentTime)))){
                    if(accProcList.get(0).Portfolio_progress_for_Accounts__c != accProcList.get(0).Records_Processed__c){
                        accProcList[0].Portfolio_progress_for_Accounts__c = 0;
                        accProcList[0].Records_Processed__c = 0;
                        resetFlag = true;
                    }
                    if(accProcList.get(0).Portfolio_Assignment_Updated__c){
                        accProcList[0].Portfolio_Assignment_Updated__c = false;
                        resetFlag = true;
                    }
                    if(resetFlag){
                        update accProcList;
                    }
                }
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getStackTraceString()+exp.getLineNumber());
        }
    }
}