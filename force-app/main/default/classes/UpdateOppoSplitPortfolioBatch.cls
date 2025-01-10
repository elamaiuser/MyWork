global class UpdateOppoSplitPortfolioBatch implements Database.Batchable<sObject>, Schedulable  {
    
    private String query;
    
    global UpdateOppoSplitPortfolioBatch (String soql){
        query = soql;
    }
    
    // The batch job starts
    global Database.Querylocator start(Database.BatchableContext bc){
        //String query = 'SELECT Id, Name FROM Account';
        System.debug('>>>> start ' + query);
        return Database.getQuerylocator(query);
    } 
    
    // The batch job executes and operates on one batch of records
    global void execute(Database.BatchableContext bc, List<OpportunitySplit> scope){
        List<List<OpportunitySplit>> processingResults;
        List<OpportunitySplit> changedOppoSplits;
        List<OpportunitySplit> errorOppoSplits;
        Map<Id,String> errorMsgMap = new Map<Id,String>();
        System.debug('>>>> execute ' + scope.size());
        
        if(scope.size() > 0) {
            
            processingResults = OpportunitySplitService.addTeamMemberPortfolio(scope);
            System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() processingResults : ' + JSON.serialize(processingResults));
            if(processingResults != null && processingResults.size() == 2) {
                System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() Starting Processing...');
                changedOppoSplits = processingResults[0];                
                errorOppoSplits = processingResults[1];
                
                if(changedOppoSplits != null && changedOppoSplits.size() > 0) {
                    System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() changedOppoSplits : ' + JSON.serialize(changedOppoSplits));
                    for(OpportunitySplit oppoSplitChange : changedOppoSplits){
                        //adding error message to error map against opportunity split id
                        errorMsgMap.put(oppoSplitChange.Id,'The Team Member has moved to a different Portfolio. Please verify if the current portfolio of the Team Member is appropriate for the Opportunity Split. Otherwise remove the Member and add as appropriate.');
                    }
                    
                    //updating changed oppo splits
                    Database.SaveResult[] results = Database.update(changedOppoSplits, false);
                    
                    // Iterate SaveResult array to capture opportunity split update errors
                    for (Database.SaveResult result : results) {
                        if (result.isSuccess()) {
                            //Successfully inserted
                            System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() Opportunity split Successfully Updated, Id is: ' + result.getId());
                        }
                        else {
                            System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() Opportunity split Updated Error, Id is: ' + result.getId());
                            string dbErrorMsg = 'Portfolio of the Team Member could not be updated due to the following errors : \\n';
                            //Error ecountered              
                            for(Database.Error error : result.getErrors()) {
                                //collating all errors for one opportunity split in one string
                                dbErrorMsg = dbErrorMsg + '\\n' + error.getStatusCode() + ': ' + error.getMessage() + 
                                        ' Fields that affected the error: ' + error.getFields();
                                
                            }
                            //adding error message to error map against opportunity split id
                            errorMsgMap.put(result.getId(),dbErrorMsg);
                            System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() Opportunity split Updated Error, Error Msg is: ' + dbErrorMsg);
                        }
                    }
                    
                }
                //collecting opportunity split with errors.
                if(errorOppoSplits != null && errorOppoSplits.size() > 0) {
                    System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() errorOppoSplits : ' + JSON.serialize(errorOppoSplits));
                    for(OpportunitySplit oppoSplitError: errorOppoSplits){
                        //adding error message to error map against opportunity split id
                        errorMsgMap.put(oppoSplitError.Id,'The team member that you selected does not have a corresponding portfolio. Team members need to be associated to a Portfolio in order to be added to a split. Please review and take corrective action.');
                    }
                }
                System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() errorMsgMap : ' + JSON.serialize(errorMsgMap));
                Map<Id,opportunitySplit> oppoSplitMap = new Map<Id,opportunitySplit>([select Id, OpportunityId, Opportunity.AccountId, Opportunity.Account.District_Manager__c, BSF_Portfolio__c, SplitOwnerId, SplitOwner.Name FROM OpportunitySplit WHERE Id IN: errorMsgMap.keySet()]);
                
                //create task for Errors
                List<task> taskList = new list<task>();
                //Map<id, opportunity> oppMap = new Map<id, opportunity>([select id,Account.Account_Manager__c from opportunity where id = :oppIds]);
                Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Team Portfolio Assignment').getRecordTypeId();
                for (opportunitySplit oppoSplit : oppoSplitMap.values()) {
                    
                    task portfAssignTask = new task();
                    portfAssignTask.RecordTypeId = recTypeId;
                    portfAssignTask.ActivityDate = Helper.AddBusinessDays(Date.Today(), 1);
                    portfAssignTask.OwnerId = oppoSplit.Opportunity.Account.District_Manager__c;
                    portfAssignTask.Drive_Date__c = oppoSplit.Opportunity.Drive_Date__c; //HRP-12700
                    portfAssignTask.subject = 'Verify Opportunity Split Portfolio For : ('+ oppoSplit.SplitOwner.Name +')';
                    portfAssignTask.Description = 'Please review following Errors / Warnings for Opportunity Split Team Memeber ('+ oppoSplit.SplitOwner.Name +') : \\n \\n ' + errorMsgMap.get(oppoSplit.Id);
                    portfAssignTask.WhatId = oppoSplit.OpportunityId;
                    taskList.add(portfAssignTask);
                    System.debug('>>>>UpdateOppoSplitPortfolioBatch.execute() portfAssignTask : ' + JSON.serialize(portfAssignTask));
                }
                if (taskList.size() > 0) {
                    Database.SaveResult[] results = Database.insert(taskList, false);
                }
                
            }
        }
        
        
        
    }
    
    // The batch job finishes
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
        System.debug('>>>> finish ' + job.Status);
    }
    
    // Execute at regular intervals
    global void execute(SchedulableContext ctx){
        String soql = 'SELECT BSF_Portfolio__c,Id,OpportunityId,Opportunity.Name,SplitOwnerId FROM OpportunitySplit' 
            +' WHERE (Opportunity.Drive_Date__c >= TODAY OR Opportunity.Drive_Date__c = NULL)'
            +' AND (Opportunity.StageName NOT IN (\'Excluded\',\'Withdrawn\',\'Closed\')'
            +' OR (Opportunity.StageName = \'Closed\' AND Opportunity.Drive_Status__c NOT IN (\'Completed\',\'Cancel\')))';
        UpdateOppoSplitPortfolioBatch batch = new UpdateOppoSplitPortfolioBatch(soql);
        Database.executebatch(batch, 200);
    }  
    
}