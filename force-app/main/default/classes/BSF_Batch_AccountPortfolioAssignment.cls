//@Description: creates account portfolio assignment for account based on Taxonomy data
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate and bypass for BSF_Batch_OpportunityTeamSync)
*03/07/2025                   Harika Bolisetti           Logic for HRP-14431//Taxo Run Chaining in finish method
*****************************************************************************
*/
global class BSF_Batch_AccountPortfolioAssignment implements Database.Batchable<sObject>{
    global Decimal taxoVerKey;
    global Date startDate;
    global Date endDate;
    global String bioRecruitmentRecordType;
    global Boolean allowChaining = false;//HRP-14431
    
    
    global BSF_Batch_AccountPortfolioAssignment(String batchName,Decimal taxoVerKey,Date stDate,Date edDate){
        this.taxoVerKey = taxoVerKey;
        this.startDate = stDate;
        this.endDate = edDate;   
    }
    
    //HRP-14431
    global BSF_Batch_AccountPortfolioAssignment(String batchName,Decimal taxoVerKey,Date stDate,Date edDate,Boolean allowChaining){
        this(batchName,taxoVerKey,stDate,edDate);
        this.allowChaining = allowChaining;//HRP-14431
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        try {///HRP-14431
            bioRecruitmentRecordType = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
            String query = 'SELECT Zip_Code__c ,Start_Date__c,End_Date__c,Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,'+
                ' Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,'+
                ' RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c '+
                ' FROM Taxonomy__c WHERE RecordType.Name = :bioRecruitmentRecordType ';  
           
            //Capture start method entry in Error Log
            
           // BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='start',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
           //  insert errorLog;*////HRP-14431
           
            if(taxoVerKey != null)
                query = query + ' AND Version_Key__c = :taxoVerKey';
            else
                query = query + ' AND createddate >= :startDate AND createddate <= :endDate';
            
            //HRP-14431 
            //
            //if(this.allowChaining == true){
                BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='start',Type__c='Success',
                                                                 Error_Description__c='Batch Process started',Error_Description_Long__c= query);
                errorLogList.add(errorLog);
                Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
                Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_AccountPortfolioAssignment','Start','Error',
                                         'Error occurred while inserting the error Record',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxoVerKey);
          //  }
            return Database.getQueryLocator(query);
        } catch (Exception e) {///HRP-14431
            // Log the error details in case of an exception
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_AccountPortfolioAssignment', 'Start Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxoVerKey);
            return null;
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Taxonomy__c> taxoList)
    {
        try {///HRP-14431
            AccountPortfolioAssignmentHelper protfolioAssignmentHelper = new AccountPortfolioAssignmentHelper();
            protfolioAssignmentHelper.assignAccountToPortfolio(taxoList,null);
        }
        catch (Exception e) {///HRP-14431
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_AccountPortfolioAssignment', 'Execute Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c', BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxoVerKey);
            
        }
    }
    global void finish(Database.BatchableContext BC)
    {
        try {///HRP-14431
            //Capture finish method entry in Error Log
            //   BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='finish',Type__c='Success',Error_Description__c='startDate ='+startDate+': endDate ='+endDate,Error_Description_Long__c='');
            //insert errorLog;
            //
            //HRP-14431
            //Capture finish method entry in Error Log
           // if(this.allowChaining == true){
            /*    List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
                BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Assign Account to Portfolio',ApexClass__c='BSF_Batch_AccountPortfolioAssignment',Method__c='finish',Type__c='Success',Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
                errorLogList.add(errorLog);//HRP-14431
                Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
                Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_AccountPortfolioAssignment','finish','Error',
                                         'Error occurred while inserting the error Record',BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxoVerKey);*/
                
                // Publish a platform event instead of inserting BSF_Error_Log__c
                Account_Portfolio_Error_Log_Event__e event = new Account_Portfolio_Error_Log_Event__e(
                    Process_Name__c = 'Assign Account to Portfolio',
                    ApexClass__c = 'BSF_Batch_AccountPortfolioAssignment',
                    Method__c = 'finish',
                    Type__c = 'Success',
                    Error_Description__c = 'Batch Process Completed'
                );
                
                // Use the EventBus to publish it
                Database.SaveResult result = EventBus.publish(event);
         //   }
            System.debug('allowChaining'+allowChaining);
            //HRP-10890
            if(allowChaining == false){///HRP-14431
                Datetime batchEndDate = system.now();
                BatchByPassSettings__mdt batchBypass = BSF_Utilities.metaDataupdate(null,batchEndDate,false,'Opportunity_Team_Sync_Batch');//HRP-10890
                if(!(batchBypass.By_Pass_Batch__c || batchBypass.Manual_By_pass__c))//HRP-10890
                {
                    system.debug('Executing Opportunity Team Sync batch');
                    system.debug('BatchSize----->'+integer.valueof(batchBypass.Batch_Size__c));
                    system.debug('BatchStartTime----->'+(batchBypass.Start_Datetime__c));
                    BSF_Batch_OpportunityTeamSync batch = new BSF_Batch_OpportunityTeamSync(batchBypass.Start_Datetime__c,batchEndDate);
                    database.executeBatch(batch,integer.valueof(batchBypass.Batch_Size__c));
                }  
                else
                {
                    system.debug('The Opportunity Team Sync batch is Bypassed');
                }
                
            }
            //HRP-14431
            else{
               
                
                Datetime batchEndDate = system.now();
                BatchByPassSettings__mdt batchBypass = BSF_Utilities.metaDataupdate(null,batchEndDate,false,'Opportunity_Team_Sync_Batch');
               System.debug('batchBypass'+batchBypass.By_Pass_Batch__c);
               
                   
                Datetime startDateTime = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
                // Get the user's time zone
                TimeZone estTimeZone = TimeZone.getTimeZone('America/New_York');
                // Convert to EST
                Datetime estDateTime = startDateTime.addSeconds(estTimeZone.getOffset(startDateTime) / 1000);
                System.debug('EST Datetime: ' + estDateTime);
                Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, 'BSF_Batch_OpportunityTeamSync');   
                BSF_Batch_OpportunityTeamSync batch = new BSF_Batch_OpportunityTeamSync(startDateTime, System.Now(), taxoVerKey);
                database.executeBatch(batch, batchSize);
               
            }
            //HRP-14431
        }catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_AccountPortfolioAssignment', 'Finish Method', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c', BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,taxoVerKey);
        }
    }
}