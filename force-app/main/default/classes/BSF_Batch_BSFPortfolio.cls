//@Description: created/sync BSF portfolio Data from Taxonomy Data
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 08/29/2023				  Balaji N					 Logic for HRP-10888(Finish Method: reduced batch size of BSF_Batch_TaxonomyEndDateHandler batch)
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate)
* *
*****************************************************************************
*/
global class BSF_Batch_BSFPortfolio implements Database.Batchable<sObject>,Schedulable,Database.Stateful {
    global Decimal taxoVerKey;
    global Date startDate;
    global Date endDate;
    global Boolean runAssignmentBatch = false;
    global String bioCollectionRecordType;
    global map<string,Decimal> recordTypeTaxVerMap = new map<string,Decimal>();
     
    global BSF_Batch_BSFPortfolio(Date startDate,Boolean runAssignmentBatch){
         this.startDate = startDate;
         this.runAssignmentBatch = runAssignmentBatch;
    }
     
     global BSF_Batch_BSFPortfolio(String batchName,Decimal taxoVerKey,Date stDate,Date edDate,Boolean runAssignmentBatch){
       this.taxoVerKey = taxoVerKey;
       this.startDate = stDate;
       this.endDate = edDate;
       if(this.endDate == null)
           this.endDate = System.today() - 1;
        
       if(this.startDate > this.endDate)
           this.endDate = System.today();
       
       this.runAssignmentBatch = runAssignmentBatch;
         
       BSF_Utilities.metaDataupdate(System.now(),null,true,'Opportunity_Team_Sync_Batch');//HRP-10890
       
        
    }
     
    global void execute(SchedulableContext sc) {
        system.debug('schedule');
       BSF_Batch_BSFPortfolio batch1 = new BSF_Batch_BSFPortfolio('BSF Portfolio Batch',null,this.startDate,null,runAssignmentBatch); 
       Database.executeBatch(batch1,50); //Move batch size to custom setting or custom metedata.
       this.startDate = System.today();    
    }
  
   global Database.QueryLocator start(Database.BatchableContext BC)
   {
       system.debug('BSF_Batch_BSFPortfolio start');
     bioCollectionRecordType = BSF_Constants.BIO_COLLECTION_RECORD_TYPE;  
       String query = 'SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,'+
                                              'Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,Version_Key__c,'+
                                             'RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c '+
                                             ' FROM Taxonomy__c WHERE RecordType.Name != :bioCollectionRecordType';  
       
     //Capture start method entry in Error Log
      
     BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Create Portfolio',ApexClass__c='BSF_Batch_BSFPortfolio',Method__c='start',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
     insert errorLog;
       
       if(taxoVerKey != null)
         query = query + ' AND Version_Key__c = :taxoVerKey';
       else
         query = query + ' AND createddate >= :startDate AND createddate <= :endDate';
     
       return Database.getQueryLocator(query);
   }
  
   global void execute(Database.BatchableContext bc, List<Taxonomy__c> scope)
   {
       BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
       portfolioHelper.createOrUpdatePortfolio(scope);
       
       for(Taxonomy__c tx:scope)
       {
           if(!recordTypeTaxVerMap.containsKey(tx.recordtype.name))
           {
               recordTypeTaxVerMap.put(tx.recordtype.name,tx.Version_Key__c);
           }
       }
   }
  
   global void finish(Database.BatchableContext BC)
   {
       //Capture finish method entry in Error Log
       //BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Create Portfolio',ApexClass__c='BSF_Batch_BSFPortfolio',Method__c='finish',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
       //insert errorLog;
       
       integer i =0;
       boolean runAccPortAssignmentBatch =false;
       for(string s :recordTypeTaxVerMap.keyset())
       {
           if(i==recordTypeTaxVerMap.keyset().size()-1)
           {
               runAccPortAssignmentBatch=this.runAssignmentBatch;
           }
           BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(this.recordTypeTaxVerMap.get(s),s,runAccPortAssignmentBatch,this.startDate,this.endDate);
           database.executeBatch(batch,25);//HRP-10888 changed batch size 50-->25
           i++;
       }
    }
     
 }