//@Description: end dates BSF portfolio/Bio collection objects Data as per old version taxonomy if not continues in the new version
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* *******************************************************************************************************************************************************************************************************************************************
* 08/29/2023				  Balaji N					 Logic for HRP-10888(Start Method: added orderby on Team_Code__ABM_Code__c; Finish Method: removed start,end parameters and added tax version on BSF_Batch_AccountPortfolioAssignment)
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate)
* 05/15/2024                  Balaji N                   Logic for HRP-12054
* 03/05/2025                  Harika  Bolisetti          Logic for  HRP-14298//Taxo Run Chaining in finish method
* 08/20/2025                  Satyendra Vishwakarma      Logic for  HRP-15577 - Fix for BSF_Batch_OpportunityTeamSync getting triggerred multiple times
*******************************************************************************************************************************************************************************************
*/
global class BSF_Batch_TaxonomyEndDateHandler  implements Database.Batchable<sObject>,Database.Stateful
{
    global Decimal taxVer;
    global string recordType;   
    global Boolean runAssignmentBatch;
    global Date startDate;
    global Date endDate;
    global Decimal oldTaxVersionKey;
    global Boolean allowChaining = false;//HRP-14298
    global Boolean runRecruitment = false;//HRP-14298
    
    global BSF_Batch_TaxonomyEndDateHandler (Decimal taxVer,string recordType,Boolean runAssignmentBatch,Date startDate,Date endDate)
    {
        system.debug('BSF_Batch_TaxonomyEndDateHandler started');
        this.recordType = recordType;
        this.taxVer=taxVer;
        this.runAssignmentBatch=runAssignmentBatch;
        this.startDate=startDate;
        this.endDate=endDate;
    }
    //HRP-14298
    global BSF_Batch_TaxonomyEndDateHandler (Decimal taxVer,string recordType,Boolean runAssignmentBatch,Date startDate,Date endDate,Boolean allowChaining)
    {
      
        this(taxVer,recordType,runAssignmentBatch,startDate,endDate);
        this.allowChaining = allowChaining;
    }
    
    global Database.queryLocator start(Database.BatchableContext BC) 
    {
        Decimal taxVer = this.taxVer;
        system.debug('BSF_Batch_TaxonomyEndDateHandler started');
        String query;
        try { //HRP-14298
            if(recordType!='Bio Collection BSF')
            {
                query = 'select Id,Division_Code__c,DS_Region_Code__c,ABM_Code__c,Team_Code__c,Collection_Operation_Code__c,District_Code__c,Supervisor_Code__c,DRD_Territory_Code__c,ABM_Name__c,'+
                    'End_Date__c,Portfolio_Code__c,RecordTypeId,Start_Date__c,Time_Zone__c,Type__c,Version_Key__c,Zip_Code__c,RecordType.Name,DRD_Territory_Name__c '+
                    'from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c != :taxVer order by Version_Key__c,Team_Code__c,ABM_Code__c,DRD_Territory_Code__c desc';//HRP-10888 added orderby on Team_Code__ABM_Code__c
                
            }
            
            if(recordType=='Bio Collection BSF')
            {
                query = 'select Id,Division_Code__c,District_Code__c,DS_Region_Code__c,Collection_Operation_Code__c,skedulo_region_cd__c,End_Date__c,Start_Date__c,Time_Zone__c,'+
                    'RecordTypeId,Supervisor_Code__c,Version_Key__c,Zip_Code__c,RecordType.Name from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c != :taxVer order by Version_Key__c,District_Code__c desc';
            }
            system.debug(query);  
            //HRP-14298
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Recruitment',ApexClass__c='BSF_Batch_TaxonomyEndDateHandler',Method__c='start',Type__c='Success',Error_Description__c='Batch Process Started',Error_Description_Long__c= query);
            errorLogList.add(errorLog);
            // insert errorLog;
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',recordType,taxVer);
            return Database.getqueryLocator(query);
        } catch (Exception e) { //HRP-14298
            System.debug('Error in start method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxonomyEndDateHandler', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',recordType,taxVer);
            return null;
        }
    }
    
     global void execute(Database.BatchableContext BC, List<Taxonomy__c> taxonomyRecords) 
    {
        try { //HRP-14298
            BSF_Constants.isEndateBatch=true;
            //system.debug('taxonomyRecords'+taxonomyRecords);
            if(oldTaxVersionKey == null)
            {
                list<Taxonomy__c> txList = [select id,Version_Key__c from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c != :taxVer order by Version_Key__c desc limit 1];
                oldTaxVersionKey =txList[0].Version_Key__c;
                //system.debug('oldTaxVersionKey'+oldTaxVersionKey);
            }
            
            set<string> amCode = new set <String>();
            set<string> abmCode = new set <String>();
            set<string> dmCode = new set <String>();
            set<string> rdseCode = new set <String>();
            set<string> dvspCode = new set <String>();
            set<string> districtCode = new set <String>();
            set<string> arcRegionCode = new set <String>();
            set<string> divisionCode = new set <String>();
            for(Taxonomy__c tx:taxonomyRecords)
            {
                if(tx.RecordType.Name == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)
                {
                    amCode.add(tx.DRD_Territory_Code__c);
                    abmCode.add(tx.ABM_Code__c);
                    dmCode.add(tx.Team_Code__c);
                    rdseCode.add(tx.DS_Region_Code__c);
                    dvspCode.add(tx.Division_Code__c);
                }
                
                if(tx.RecordType.Name == BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
                {
                    districtCode.add(tx.District_Code__c);
                    arcRegionCode.add(tx.DS_Region_Code__c);
                    divisionCode.add(tx.Division_Code__c);
                }
                
            }
            List<Taxonomy__c> newVersionTaxList = new List<Taxonomy__c> ();
            
            if(recordType != BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE && recordType != BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
            {
                newVersionTaxList = [select Division_Code__c,DS_Region_Code__c,ABM_Code__c,Team_Code__c,Collection_Operation_Code__c,District_Code__c,Supervisor_Code__c,DRD_Territory_Code__c,ABM_Name__c,
                                     End_Date__c,Id,Portfolio_Code__c,RecordTypeId,Start_Date__c,Version_Key__c,Zip_Code__c,
                                     RecordType.Name from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c = :taxVer order by Version_Key__c desc];
            }
            
            if(recordType == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE )
            {
                newVersionTaxList = [select Division_Code__c,DS_Region_Code__c,ABM_Code__c,Team_Code__c,Collection_Operation_Code__c,District_Code__c,Supervisor_Code__c,DRD_Territory_Code__c,ABM_Name__c,
                                     End_Date__c,Id,Portfolio_Code__c,RecordTypeId,Start_Date__c,Version_Key__c,Zip_Code__c,
                                     RecordType.Name from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c = :taxVer and
                                     (DRD_Territory_Code__c IN:amCode or ABM_Code__c IN:abmCode or Team_Code__c IN:dmCode or DS_Region_Code__c IN:rdseCode  or Division_Code__c IN:dvspCode) order by Version_Key__c desc];
            }
            
            if(recordType == BSF_Constants.BIO_COLLECTION_RECORD_TYPE )
            {
                newVersionTaxList = [select Id,Division_Code__c,District_Code__c,DS_Region_Code__c,Collection_Operation_Code__c,skedulo_region_cd__c,End_Date__c,Start_Date__c,Time_Zone__c,
                                     RecordTypeId,Supervisor_Code__c,Version_Key__c,Zip_Code__c,RecordType.Name from Taxonomy__c where RecordType.Name =:recordType AND Version_Key__c = :taxVer and
                                     (District_Code__c IN:districtCode or DS_Region_Code__c IN:arcRegionCode or Division_Code__c IN:divisionCode) order by Version_Key__c desc];
            }
            
            
            List<Taxonomy__c> oldVersionTaxRecords = new List<Taxonomy__c>();
            for(Taxonomy__c tx : taxonomyRecords)
            {
                /*if(this.oldTaxVersionKey == null)
{
this.oldTaxVersionKey =tx.Version_Key__c;
system.debug('oldTaxVersionKey'+oldTaxVersionKey);
}*/
                if(tx.Version_Key__c  == this.oldTaxVersionKey)
                {
                 
                    oldVersionTaxRecords.add(tx);
                    //system.debug('tx'+tx);
                    
                }
            }
            //system.debug('oldVersionTaxRecords'+oldVersionTaxRecords);
            //system.debug('newVersionTaxList'+newVersionTaxList);
            BSF_Batch_TaxonomyEndDateHelper.endDateTaxonomy(newVersionTaxList,oldVersionTaxRecords);
          
        } catch (Exception e) { //HRP-14298
            System.debug('Error in execute method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxonomyEndDateHandler', 'Execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',recordType,taxVer);
        }
    }
    
    
    global void finish(Database.BatchableContext BC) {
        List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>();
        List<Taxonomy_Run__c> updateTaxoRun = new List<Taxonomy_Run__c>();
        
        try { 
            //HRP-14298 
            //Capture finish method entry in Error Log
            if (this.recordType == BSF_Constants.BIO_COLLECTION_RECORD_TYPE 
                || this.recordType == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ){
                    List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
                    BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Recruitment',ApexClass__c='BSF_Batch_TaxonomyEndDateHandler',Method__c='finish',Type__c='Success',
                                                                     Error_Description__c='Batch Process Completed' ,Error_Description_Long__c='');
                    errorLogList.add(errorLog);
                    // insert errorLog;
                    
                    Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
                    Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_TaxonomyEndDateHandler','Finish','Error',
                                             'Error occurred while inserting the error Record',recordType,taxVer);
                    system.debug('The BSF_Batch_TaxonomyEndDateHandler is completed');
                }
            if (this.recordType != BSF_Constants.BIO_COLLECTION_RECORD_TYPE) { 
                
                BatchByPassSettings__mdt accPortbatchBypass = BSF_Utilities.metaDataupdate(null, null, null, 'Account_Portfolio_Assignment_Batch');
                //RecordType:Bio Recruitment CD
                system.debug('HRP-15577 The runAssignmentBatch :'+this.runAssignmentBatch);
                if (this.runAssignmentBatch) {
                    
                    system.debug('Executing AccountPortfolioAssignment batch');
                    system.debug('BatchSize----->' + integer.valueOf(accPortbatchBypass.Batch_Size__c));
                    BSF_Batch_AccountPortfolioAssignment batch2 = new BSF_Batch_AccountPortfolioAssignment('BSF AccountPortfolio Assignment Batch', taxVer, null, null, allowChaining);
                    Database.executeBatch(batch2, integer.valueOf(accPortbatchBypass.Batch_Size__c));
                    
                    if (allowChaining) {
                        chainTaxonomyBatch();//HRP-14298
                    }
                }
                
                //All RecordTypes(Except Bio Recruitment CD,Bio Collection BSF)
                else {
                   
                    system.debug('HRP-15577 The AccountPortfolioAssignment batch is Bypassed ');
                    system.debug('HRP-15577 BatchSize------>'+integer.valueof(accPortbatchBypass.Batch_Size__c));
                    BatchByPassSettings__mdt batchBypass = BSF_Utilities.metaDataupdate(null,System.now(),false,'Opportunity_Team_Sync_Batch');//HRP-10890
                    
                    
                    String externalid = this.recordType + '_' + Integer.valueOf(this.taxVer);
                    System.debug('externalid' + externalid);
                    //HRP-14298
                    List<Taxonomy_Run__c> taxonomyRuns = [
                        SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                        FROM Taxonomy_Run__c 
                        WHERE External_Id__c = :externalid LIMIT 1];
                    
                    if (!taxonomyRuns.isEmpty()) {
                        Taxonomy_Run__c txr = taxonomyRuns[0];
                        publishTaxonomyRunUpdateEvent(txr.Id);
                    }
                    else{
                       publishTaxonomyRunUpdateEvent(null); 
                    }
                    if (allowChaining) {
                        //  Schedule the Batch  after 1 minute 
                        Datetime dt = Datetime.now().addMinutes(1);
                        String cronExp = String.format('{0} {1} {2} {3} {4} ? {5}',
                                                       new String[] {
                                                           String.valueOf(dt.second()), 
                                                               String.valueOf(dt.minute()), 
                                                               String.valueOf(dt.hour()), 
                                                               String.valueOf(dt.day()), 
                                                               String.valueOf(dt.month()), 
                                                               String.valueOf(dt.year())
                                                               });
                        
                        System.schedule('BSF_Batch_BSFPortfolio-'+recordType+'-'+taxVer + Datetime.now().getTime(), cronExp, new DelayedTaxonomyBatchScheduler());
                        
                    }
                }
            }
            
             
            // If record type is Bio Collection BSF
            // 
            if(this.recordType == BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
            {
                //if(!test.isRunningTest()){
                    //Database.executebatch(new skedCollectionsZipCodeBatch(),200);//HRP-12054
                    Integer batchSize = Taxo_Utilities.getBatchSize(this.recordType, 'BSF_Batch_GenerateCollectionZipcode');
                    Database.executebatch(new BSF_Batch_GenerateCollectionZipcode (this.taxVer,null,null,this.allowChaining),batchSize);//HRP-12054
                    //HRP-14298
                    if (allowChaining) {
                        chainTaxonomyBatch();
                        
                    }
               // }
            } 
            //HRP-14298(//If Bio Recruitment CD is not in the list of Taxononmy run records, then Run the Oppportunity team sync)
            if(this.allowChaining == true){
                List<Taxonomy_Run__c> txrnRecords = [
                    SELECT Id, Taxo_Record_Type__c,Status__c,Future_Version_Number__c, Sequence__c
                    FROM Taxonomy_Run__c 
                    WHERE Run_Date__c = TODAY AND Status__c = 'Pending'  
                    ];
                if(txrnRecords.isEmpty()){
                    List<Taxonomy_Run__c> recruitmenttaxorun = [
                        SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                        FROM Taxonomy_Run__c 
                        WHERE Run_Date__c = TODAY AND Taxo_Record_Type__c = :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE 
                       ];
                    if (recruitmenttaxorun.isEmpty()) {
                        // Taxonomy_Run__c recruitmenttxrn = recruitmenttaxorun[0];
                        Datetime startDateTime = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
                        // Get the user's time zone
                        TimeZone estTimeZone = TimeZone.getTimeZone('America/New_York');
                        // Convert to EST
                        Datetime estDateTime = startDateTime.addSeconds(estTimeZone.getOffset(startDateTime) / 1000);
                        System.debug('EST Datetime: ' + estDateTime);
                        Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, 'BSF_Batch_OpportunityTeamSync');   
                        BSF_Batch_OpportunityTeamSync batch = new BSF_Batch_OpportunityTeamSync(startDateTime, System.Now(),null);
                        database.executeBatch(batch, batchSize);
                    }
                }
            }
            
            
        }catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_TaxonomyEndDateHandler', 'Finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',recordType,taxVer);
            
            
        }
        
    }
    //if status is completed.    
    private void publishTaxonomyRunUpdateEvent(Id taxonomyRunId) {
        
        if(taxonomyRunId !=null){
        TaxonomyRunUpdateEvent__e event = new TaxonomyRunUpdateEvent__e(
            TaxonomyRunId__c = taxonomyRunId,
            Status__c = 'Completed',
            RecordType__c = recordType,
            taxVer__c = taxVer,
            ProcessingEndDate__c = System.now()
        );
        EventBus.publish(event);
    }
    }    
    //method to chain the records
    //
    private void chainTaxonomyBatch() {
        List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>(); 
        try { 
            List<Taxonomy_Run__c> taxonomyRuns = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                                                  FROM Taxonomy_Run__c 
                                                  WHERE Run_Date__c = TODAY AND Status__c = 'Pending' 
                                                  ORDER BY Sequence__c ASC LIMIT 1];
            
            if (!taxonomyRuns.isEmpty()) {
                Taxonomy_Run__c txrn = taxonomyRuns[0];
                if (txrn == null) return;
                Integer batchSize;
                
                if (txrn.Taxo_Record_Type__c == BSF_Constants.BIO_COLLECTION_RECORD_TYPE) {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_PopulateCORegion');
                    //Database.executeBatch(new BSF_Batch_PopulateCORegion(null,txrn.Future_Version_Number__c,this.allowChaining), batchSize);
                    // NEW (scheduled by metadata delay):
                    Taxo_Utilities.scheduleAfterDelay(
                        new BSF_Batch_PopulateCORegionScheduler(txrn.Future_Version_Number__c, true, batchSize),
                        txrn.Taxo_Record_Type__c,
                        'BSF_Batch_PopulateCORegion'
                    ); 
                } 
                else if (txrn.Taxo_Record_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE) {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');
                    //Database.executeBatch(new BSF_Batch_BSFPortfolio(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, null, null, true, this.allowChaining), batchSize);
                    // Recruitment case NEW (scheduled by metadata delay):
                    Boolean runAssign = true;  
                    Taxo_Utilities.scheduleAfterDelay(
                        new BSF_Batch_BSFPortfolioScheduler(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, runAssign, true, batchSize),
                        txrn.Taxo_Record_Type__c,
                        'BSF_Batch_BSFPortfolio'
                    );
                } 
                else {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');
                    //Database.executeBatch(new BSF_Batch_BSFPortfolio(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, null, null, false, this.allowChaining), batchSize);
                    // For non-recruitment record types NEW (scheduled by metadata delay):
                    Boolean runAssignFalse = false;
                    Taxo_Utilities.scheduleAfterDelay(
                        new BSF_Batch_BSFPortfolioScheduler(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, runAssignFalse, true, batchSize),
                        txrn.Taxo_Record_Type__c,
                        'BSF_Batch_BSFPortfolio'
                    );
                }
            }
        }catch (Exception e) {
            Taxo_Utilities.logErrorForException(e, 'Taxonomy Run', 'TaxonomyRunBatchHandler', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',recordsToUpdate[0].Taxo_Record_Type__c, recordsToUpdate[0].Future_Version_Number__c);
            
        }
        
        
    }
    
    
    
}