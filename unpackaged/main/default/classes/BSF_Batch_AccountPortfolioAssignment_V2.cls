global class BSF_Batch_AccountPortfolioAssignment_V2 implements Database.Batchable<sObject>{
	global String bioRecruitmentRecordType;
    global Decimal taxoVerKey;
    global List<String> postalcodeList;
    
    global BSF_Batch_AccountPortfolioAssignment_V2(Decimal taxoVerKey){
      this.bioRecruitmentRecordType = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
      this.taxoVerKey = taxoVerKey;  
      this.postalcodeList = new List<String>(); 
   }
    
  global Database.QueryLocator start(Database.BatchableContext BC)
  {
        
     String accountQuery = 'Select Id,Name,BillingPostalCode FROM Account WHERE Account_AM_Portfolio_Type__c = FALSE';
  	
    return Database.getQueryLocator(accountQuery);
  }
 
  global void execute(Database.BatchableContext bc, List<Account> accountList)
  {
        postalcodeList.clear();
        for(Account acc:accountList){
        	postalcodeList.add(acc.BillingPostalCode);      
        }
      
        String taxonomyQuery = 'SELECT Zip_Code__c ,Start_Date__c,End_Date__c,Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,'+
                                             ' Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,'+
                                             ' RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c '+
                                             ' FROM Taxonomy__c WHERE RecordType.Name = :bioRecruitmentRecordType  AND Version_Key__c = :taxoVerKey AND Zip_Code__c IN :postalcodeList'; 
       
        List<Taxonomy__c> taxoList = Database.query(taxonomyQuery);
        
        System.debug(' postalcodeList '+postalcodeList);
        System.debug(' taxoList '+taxoList.size());
      
		AccountPortfolioAssignmentHelper protfolioAssignmentHelper = new AccountPortfolioAssignmentHelper();
        protfolioAssignmentHelper.assignAccountToPortfolio(taxoList,accountList);
  }
    
  global void finish(Database.BatchableContext BC)
  {
       //Capture finish method entry in Error Log
  }
}