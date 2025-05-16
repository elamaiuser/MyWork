//@Description: creates Opportunity Team from account Team Member
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 03/10/2025                   Harika Bolisetti           Logic for HRP-14433//Taxo Run Chaining in finish method
*****************************************************************************
*/
global class BSF_Batch_OpportunityTeamSync implements Database.Batchable<sObject>{ 
    global Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers;
    global Integer countAccounts;
    global Date leastStartDate;
    global Date maxEndDate;
    //HRP-10889
    global String STAGE_CANCELLED = BSF_constants.STAGE_CANCELLED;
    global DateTime teamMemberModifiedStart;
    global DateTime teamMemberModifiedEnd;
    //HRP-14433
    global DateTime startTime;
    global Decimal taxVer;
    //HRP-10889
    global BSF_Batch_OpportunityTeamSync(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,Integer countAccounts,Date startDate,Date endDate){
        this.mapOfAcctsWithTeamMembers = mapOfAcctsWithTeamMembers;
        this.countAccounts = countAccounts;
        this.leastStartDate = startDate;
        this.maxEndDate = endDate;
    }
    //HRP-10889
    global BSF_Batch_OpportunityTeamSync(DateTime teamMemberModifiedStart,DateTime teamMemberModifiedEnd){
        this.mapOfAcctsWithTeamMembers = new Map<Id,List<AccountTeamMember>>();
        this.countAccounts = 0;
        this.teamMemberModifiedStart = teamMemberModifiedStart;
        this.teamMemberModifiedEnd = teamMemberModifiedEnd;
        
    }
    //HRP-14433
    //
    global BSF_Batch_OpportunityTeamSync(DateTime teamMemberModifiedStart,DateTime teamMemberModifiedEnd,Decimal taxVer){
        this.mapOfAcctsWithTeamMembers = new Map<Id,List<AccountTeamMember>>();
        this.countAccounts = 0;
        this.teamMemberModifiedStart = teamMemberModifiedStart;
        this.teamMemberModifiedEnd = teamMemberModifiedEnd;
        this.taxVer = taxVer;
    }
    //HRP-10889
    global Database.QueryLocator start(Database.BatchableContext BC)
    { 
        try{
            Set<Id> accountIds = mapOfAcctsWithTeamMembers.keySet();
            //Date leastStartDate = null;
            //Date maxEndDate = null;
            /*for(Id acctId : mapOfAcctsWithTeamMembers.keySet()){
for(AccountTeamMember actTeamMember :mapOfAcctsWithTeamMembers.get(acctId)){
if(leastStartDate == null || leastStartDate > actTeamMember.Start_Date__c){
leastStartDate = actTeamMember.Start_Date__c;
}
if(maxEndDate == null || maxEndDate < actTeamMember.End_Date__c){
maxEndDate = actTeamMember.End_Date__c;
}
}
}*/
            String query = 'SELECT Id, ownerId, AccountId, Drive_Date__c, Account_Manager__c, Account_Manager_Portfolio__c ,Covering_Recruiter__c,District_Manager__c, District_Manager_Portfolio__c FROM Opportunity WHERE AccountId IN :accountIds AND Drive_Date__c != null AND StageName != :STAGE_CANCELLED AND Drive_Date__c >= :leastStartDate AND Drive_Date__c <= :maxEndDate';//HRP-13340
            //HRP-10889  //HRP-10359
            if(mapOfAcctsWithTeamMembers.isEmpty()){
                query = 'SELECT Id, ownerId, AccountId, Drive_Date__c, Account_Manager__c,Covering_Recruiter__c,District_Manager__c, Account_Manager_Portfolio__c, District_Manager_Portfolio__c FROM Opportunity WHERE AccountId IN (SELECT AccountId FROM AccountTeamMember WHERE Lastmodifieddate >=:teamMemberModifiedStart AND Lastmodifieddate <= :teamMemberModifiedEnd) AND Drive_Date__c != null AND Drive_Date__c >= TODAY AND StageName != :STAGE_CANCELLED ';
            }
            //HRP-14433 
           //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Recruitment',ApexClass__c='BSF_Batch_OpportunityTeamSync',
                                                             Method__c='start',Type__c='Success',Error_Description__c='Batch Process Started',Error_Description_Long__c= query);
            errorLogList.add(errorLog);
            // insert errorLog;           
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
            return Database.getQueryLocator(query); 
        } catch (Exception e) {
            // Log the error details in case of an exception
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_OpportunityTeamSync', 'Start Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        try {
            List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert = new List<OpportunityTeamMember>();
            //HRP-10889
            if(mapOfAcctsWithTeamMembers.isEmpty()){
                Set<Id> accountIdSet = new Set<Id>();
                for(Opportunity oppty:scope){
                    accountIdSet.add(oppty.AccountId);
                }
                List<AccountTeamMember> listOfAcctteammembers=[SELECT Id,AccountId,Account.Account_Manager__c,account.District_Manager__c,UserId, TeamMemberRole, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, Start_Date__c, End_Date__c, Coverage_Reason__c, Is_Covering_Recruiter__c, 
                                                               BSF_Portfolio__c FROM AccountTeamMember where AccountId IN:accountIdSet order by createddate desc];
                for(AccountTeamMember atmRecord:listOfAcctteammembers){   
                    if(mapOfAcctsWithTeamMembers.containsKey(atmRecord.AccountId)){
                        List<AccountTeamMember> listOfExistAcctTeamMembers= mapOfAcctsWithTeamMembers.get(atmRecord.AccountId);
                        listOfExistAcctTeamMembers.add(atmRecord);
                        mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,listOfExistAcctTeamMembers);
                    } else {       
                        mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,new List<AccountTeamMember>{atmRecord});     
                    }
                }
            }
            //HRP-10889
            AccountTeamMemberService.addAcctTeamMembers_To_BloodDriveOpptyMembers(mapOfAcctsWithTeamMembers,scope,listOfOpptyTeamMembersTodelete,optyTeamMemberNotExistListToInsert);
            
            OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true; 
            if(listOfOpptyTeamMembersTodelete.size() > 0){
                Database.DeleteResult[] drList = Database.delete(listOfOpptyTeamMembersTodelete,false);
                for(Database.DeleteResult dr : drList) {
                    if (!dr.isSuccess()) {
                        for(Database.Error err : dr.getErrors()) {
                            System.debug('Error Deleting teammember record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                        }
                    }
                }
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(drList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamSync','Error','Error in deleting Opportunity Team');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            
            if(optyTeamMemberNotExistListToInsert.size() > 0){
                Database.SaveResult[] srList = Database.insert(optyTeamMemberNotExistListToInsert, false);
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred in AccountTeamMemberService Insert.'+err.getStatusCode() + ': ' + err.getMessage());                    
                        }	
                    }
                }
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamSync','Error','Error in adding Opportunity Team');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
        } catch (Exception e) {
            // Log the error details in case of an exception
           //HRP-14433
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_OpportunityTeamSync', 'Execute Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
            
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        //insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='BSF_Batch_OpportunityTeamSync',Method__c='finish',Type__c='Success',Error_Description__c='countAccounts '+String.valueOf(countAccounts));
        // HRP-14433
        //  //Capture finish method entry in Error Log
        List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Recruitment',ApexClass__c='BSF_Batch_OpportunityTeamSync',Method__c='finish',Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='countAccounts '+String.valueOf(countAccounts));
        errorLogList.add(errorLog);//
        //insert errorLog;
        Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
        Taxo_Utilities.logErrors(insertResult, 'Taxonomy Run', 'BSF_Batch_OpportunityTeamSync', 'Finish', 'Error', 
                                 'Error occurred while inserting the error log',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
        
        
        try {        
            List<Portfolio_Accounts_Processing__c> pt = [Select Id, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1 FOR UPDATE];	
            if (pt.size() > 0) {	
                pt[0].Records_Processed__c += countAccounts;	
                Database.SaveResult[] updateResults = Database.update(pt, false);//HRP-14433
                // update pt;	
                // 
                Taxo_Utilities.logErrors(updateResults, 'Taxonomy Run', 'BSF_Batch_OpportunityTeamSync', 'Finish', 'Error', 
                                         'Error occurred while updating the Record',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
                
            } 
            //HRP-14433
            List<Taxonomy_Run__c> updateTaxoRun = new List<Taxonomy_Run__c>();
            List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>();
            System.debug('taxVer'+taxVer);
            if(taxVer!=null){
                Taxonomy_Run__c txr = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                                       FROM Taxonomy_Run__c 
                                       WHERE Future_Version_Number__c =:taxVer and Taxo_Record_Type__c =:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];{
                                           txr.Status__c = 'Completed';
                                           txr.Processing_End__c = System.now();
                                           updateTaxoRun.add(txr);
                                       }
                
                if (!updateTaxoRun.isEmpty()) {
                    
                    Database.SaveResult[] updateResults = Database.update(updateTaxoRun, false);
                    Taxo_Utilities.logErrors(updateResults,'Taxonomy Run','BSF_Batch_OpportunityTeamSync','Finish','Error',
                                             'Error occured in while updating the Taxonomy Run Record',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
                }
                
            } 
        }catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxoRunControlBatch', 'Finish Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxVer);
        }
        
    }
    
    
}