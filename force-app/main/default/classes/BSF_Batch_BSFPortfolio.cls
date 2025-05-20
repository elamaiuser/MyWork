//@Description: created/sync BSF portfolio Data from Taxonomy Data
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ****************************************************************************************************************************************************
* 08/29/2023				  Balaji N					 Logic for HRP-10888(Finish Method: reduced batch size of BSF_Batch_TaxonomyEndDateHandler batch)
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate)
* *03/04/2025                 Harika Bolisetti           Logic  for HRP-14316(BSF_Batch_BSFPortfolio Enhancements for Taxo Run Automation)
******************************************************************************************************************************************************
*/
global class BSF_Batch_BSFPortfolio implements Database.Batchable<sObject>,Schedulable,Database.Stateful {
    global Decimal taxoVerKey;
    global Date startDate;
    global Date endDate;
    global Boolean runAssignmentBatch = false;
    global String bioCollectionRecordType;
    global map<string,Decimal> recordTypeTaxVerMap = new map<string,Decimal>();
    
    //HRP-14316
    global Boolean allowChaining = false;
    global String recordType;
  
    
    global BSF_Batch_BSFPortfolio(Date startDate,Boolean runAssignmentBatch){
        this.startDate = startDate;
        this.runAssignmentBatch = runAssignmentBatch;
    }
    
    
    //Taxo Allow Chaining
    //HRP-14316
    global BSF_Batch_BSFPortfolio(String batchName, Decimal taxoVerKey, Date stDate, Date edDate, Boolean runAssignmentBatch, Boolean allowChaining) {
        try{//HRP-14316 
            // Call the first constructor
            this(batchName, taxoVerKey, stDate, edDate, runAssignmentBatch);
            // Additional setup specific to this constructor
            this.allowChaining = allowChaining;
        }  catch (Exception e) {//HRP-14316
            Taxo_Utilities.logErrorForException( e,'BSF_Batch_BSFPortfolio', 'Constructor', e.getMessage(),e.getMessage(),'Taxonomy_Run__c',recordType,taxoVerKey);  
        }    
        
    }
    
    
    global BSF_Batch_BSFPortfolio(String batchName,Decimal taxoVerKey,Date stDate,Date edDate,Boolean runAssignmentBatch){
        try{//HRP-14316
            this.recordType = batchName;
            this.taxoVerKey = taxoVerKey;
            this.startDate = stDate;
            this.endDate = edDate;
            if(this.endDate == null)
            this.endDate = System.today() - 1;
            
            if(this.startDate > this.endDate)
            this.endDate = System.today();
            
            this.runAssignmentBatch = runAssignmentBatch;
            
            BSF_Utilities.metaDataupdate(System.now(),null,true,'Opportunity_Team_Sync_Batch');//HRP-10890
       
        }  catch (Exception e) {//HRP-14316
            Taxo_Utilities.logErrorForException( e,'BSF_Batch_BSFPortfolio', 'Constructor', e.getMessage(),e.getMessage(),'Taxonomy_Run__c',recordType,taxoVerKey);  
           }      
        
        
    }
    
    global void execute(SchedulableContext sc) {
        try{//HRP-14316
            system.debug('schedule');
            BSF_Batch_BSFPortfolio batch1 = new BSF_Batch_BSFPortfolio('BSF Portfolio Batch',null,this.startDate,null,runAssignmentBatch); 
            Database.executeBatch(batch1,50); //Move batch size to custom setting or custom metedata.
            this.startDate = System.today();  
            
        }catch (Exception e) {//HRP-14316
            Taxo_Utilities.logErrorForException( e,'BSF_Batch_BSFPortfolio', 'execute', e.getMessage(),e.getMessage(),'Taxonomy_Run__c',recordType,taxoVerKey);  
        }            
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        system.debug('BSF_Batch_BSFPortfolio start');
        try {//HRP-14316
            bioCollectionRecordType = BSF_Constants.BIO_COLLECTION_RECORD_TYPE;  
            String query = 'SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,'+
                'Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,Version_Key__c,'+
                'RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c '+
                ' FROM Taxonomy__c WHERE RecordType.Name != :bioCollectionRecordType';  
            
             if(recordType !=null)
            {
                query = query + ' AND RecordType.Name = :recordType';//HRP-14316    
            }
            
            if(taxoVerKey != null)
                query = query + ' AND Version_Key__c = :taxoVerKey';
            else
                query = query + ' AND createddate >= :startDate AND createddate <= :endDate';
            
            
            //Capture start method entry in Error Log
            
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Create Portfolio',ApexClass__c='BSF_Batch_BSFPortfolio',Method__c='start',Type__c='Success',Error_Description__c='Batch Process Started',Error_Description_Long__c= query);
            errorLogList.add(errorLog);//HRP-14316
            // insert errorLog;//HRP-14316
            
            //HRP-14316
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',recordType,taxoVerKey);
            return Database.getQueryLocator(query);
            
        } catch (Exception e) {////HRP-14316
            // Log the error details in case of an exception
            // 
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_BSFPortfolio', 'Start Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',recordType,taxoVerKey);
            return null;
            }
    }
    
    global void execute(Database.BatchableContext bc, List<Taxonomy__c> scope)
    {
        System.debug('scope'+scope);
        try {
            ////HRP-14316
            //Check the existing records of Tax run records with status = 'pending' or 'completed'
            List<Taxonomy_Run__c> taxoRunList = new List<Taxonomy_Run__c>();
            List<Taxonomy_Run__c> txrn = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c FROM Taxonomy_Run__c  WHERE Taxo_Record_Type__c = :recordType  AND Future_Version_Number__c = :taxoVerKey 
                                          AND Status__c IN ('Pending', 'Completed')];
            
            if (!txrn.isEmpty()) {
                Taxonomy_Run__c txr = txrn[0];
                txr.Status__c = 'Processing';
                txr.Processing_Start__c = System.now();
                Database.SaveResult[] updateResults = Database.update(txrn, false);
                
                Taxo_Utilities.logErrors(updateResults, 
                                         'Taxonomy Run',
                                         'BSF_Batch_TaxoRunControlBatch',
                                         'Execute',
                                         'Error',
                                         'Error occured in while updating the Taxonomy Run Record',
                                         txr.Taxo_Record_Type__c,
                                         txr.Future_Version_Number__c);
            }
            
            BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
            portfolioHelper.createOrUpdatePortfolio(scope);
            
            for(Taxonomy__c tx:scope)
            {
                if(!recordTypeTaxVerMap.containsKey(tx.recordtype.name))
                {
                    recordTypeTaxVerMap.put(tx.recordtype.name,tx.Version_Key__c);
                }
            } 
        } catch (Exception e) {//HRP-14316
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_BSFPortfolio', 'Execute Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c', recordType,taxoVerKey);
        }      
    }
    
    
    global void finish(Database.BatchableContext BC)
    {
        //HRP-14316
        try{
            //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Create Portfolio',ApexClass__c='BSF_Batch_BSFPortfolio',Method__c='finish',Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
            errorLogList.add(errorLog);
            //insert errorLog;
            
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Finish','Error',
                                     'Error occurred while inserting the error Record',recordType,taxoVerKey);
            
            integer i =0;
            boolean runAccPortAssignmentBatch =false;
            for(string s :recordTypeTaxVerMap.keyset())
            {
                if(i==recordTypeTaxVerMap.keyset().size()-1)
                {
                    runAccPortAssignmentBatch=this.runAssignmentBatch;
                }
                BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(this.recordTypeTaxVerMap.get(s),s,runAccPortAssignmentBatch,this.startDate,this.endDate,this.allowChaining);
                Integer batchSize = Taxo_Utilities.getBatchSize(s, 'BSF_Batch_TaxonomyEndDateHandler'); ////HRP-14295  
                database.executeBatch(batch,batchSize);////HRP-14316
                i++;
            }
        }
        catch (Exception e) {//HRP-14316
            
            Taxo_Utilities.logErrorForException(
                e, 
                'BSF_Batch_BSFPortfolio', 
                'Finish Method', 
                e.getMessage(), 
                e.getMessage(), 
                'Taxonomy_Run__c', 
                recordType,
                taxoVerKey
            );
        }   
        
    }  


}