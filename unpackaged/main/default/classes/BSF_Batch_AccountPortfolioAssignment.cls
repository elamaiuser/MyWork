//@Description: creates account portfolio assignment for account based on Taxonomy data
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate and bypass for BSF_Batch_OpportunityTeamSync)
*
*****************************************************************************
*/
global class BSF_Batch_AccountPortfolioAssignment implements Database.Batchable<sObject>{
   global Decimal taxoVerKey;
   global Date startDate;
   global Date endDate;
   global String bioRecruitmentRecordType;
   
   global BSF_Batch_AccountPortfolioAssignment(String batchName,Decimal taxoVerKey,Date stDate,Date edDate){
      this.taxoVerKey = taxoVerKey;
      this.startDate = stDate;
      this.endDate = edDate;   
   }
    
  global Database.QueryLocator start(Database.BatchableContext BC)
  {
    bioRecruitmentRecordType = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
  	String query = 'SELECT Zip_Code__c ,Start_Date__c,End_Date__c,Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,'+
                                             ' Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,'+
                                             ' RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c '+
                                             ' FROM Taxonomy__c WHERE RecordType.Name = :bioRecruitmentRecordType ';  
  	
    //Capture start method entry in Error Log
    BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='start',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
    insert errorLog;
      
  	if(taxoVerKey != null)
    	query = query + ' AND Version_Key__c = :taxoVerKey';
  	else
		query = query + ' AND createddate >= :startDate AND createddate <= :endDate';
    
  	return Database.getQueryLocator(query);
  }
 
  global void execute(Database.BatchableContext bc, List<Taxonomy__c> taxoList)
  {
		AccountPortfolioAssignmentHelper protfolioAssignmentHelper = new AccountPortfolioAssignmentHelper();
        protfolioAssignmentHelper.assignAccountToPortfolio(taxoList,null);
  }
 
  global void finish(Database.BatchableContext BC)
  {
       //Capture finish method entry in Error Log
       BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='finish',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
       //insert errorLog;
      //HRP-10890
      Datetime batchEndDate = system.now();
      BatchByPassSettings__mdt batchBypass = BSF_Utilities.metaDataupdate(null,batchEndDate,false,'Opportunity_Team_Sync_Batch');//HRP-10890
      if(!(batchBypass.By_Pass_Batch__c || batchBypass.Manual_By_pass__c))//HRP-10890
      {
          system.debug('Executing Opportunity Team Sync batch');
          system.debug('BatchSize----->'+integer.valueof(batchBypass.Batch_Size__c));
          
          BSF_Batch_OpportunityTeamSync batch = new BSF_Batch_OpportunityTeamSync(batchBypass.Start_Datetime__c,batchEndDate);
          database.executeBatch(batch,integer.valueof(batchBypass.Batch_Size__c));
       }
      else
      {
          system.debug('The Opportunity Team Sync batch is Bypassed');
      }
      //HRP-10890
      
      
  }
    
}