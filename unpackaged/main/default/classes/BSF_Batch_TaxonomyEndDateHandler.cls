//@Description: end dates BSF portfolio/Bio collection objects Data as per old version taxonomy if not continues in the new version
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 08/29/2023				  Balaji N					 Logic for HRP-10888(Start Method: added orderby on Team_Code__ABM_Code__c; Finish Method: removed start,end parameters and added tax version on BSF_Batch_AccountPortfolioAssignment)
* 09/27/2023				  Balaji N					 Logic for HRP-10890(Method call: BSF_Utilities.metaDataupdate)
*
*****************************************************************************
*/
global class BSF_Batch_TaxonomyEndDateHandler  implements Database.Batchable<sObject>,Database.Stateful
{
    
    global Decimal taxVer;
    global string recordType;   
    global Boolean runAssignmentBatch;
    global Date startDate;
    global Date endDate;
    global Decimal oldTaxVersionKey;
    global BSF_Batch_TaxonomyEndDateHandler (Decimal taxVer,string recordType,Boolean runAssignmentBatch,Date startDate,Date endDate)
    {
        system.debug('BSF_Batch_TaxonomyEndDateHandler started');
        this.recordType = recordType;
        this.taxVer=taxVer;
        this.runAssignmentBatch=runAssignmentBatch;
        this.startDate=startDate;
        this.endDate=endDate;
    }
    
    global Database.queryLocator start(Database.BatchableContext BC) 
    {
        Decimal taxVer = this.taxVer;
        system.debug('BSF_Batch_TaxonomyEndDateHandler started');
        String query;
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
        
        return Database.getqueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<Taxonomy__c> taxonomyRecords) 
    {
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
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        system.debug('The BSF_Batch_TaxonomyEndDateHandler is completed');
        BatchByPassSettings__mdt accPortbatchBypass = BSF_Utilities.metaDataupdate(null,null,null,'Account_Portfolio_Assignment_Batch');//HRP-10890
            
        if(this.runAssignmentBatch)
        {
            system.debug('Executing AccountPortfolioAssignment batch');
            system.debug('BatchSize----->'+integer.valueof(accPortbatchBypass.Batch_Size__c));
            BSF_Batch_AccountPortfolioAssignment batch2 = new BSF_Batch_AccountPortfolioAssignment('BSF AccountPortfolio Assignment Batch',taxVer,null,null);//HRP-10888 removed start,end parameters and added tax version
            Database.executeBatch(batch2,integer.valueof(accPortbatchBypass.Batch_Size__c));//HRP-10890 Moved batch size to custom metedata
        }
        else
        {
            system.debug('The AccountPortfolioAssignment batch is Bypassed ');
            system.debug('BatchSize----->'+integer.valueof(accPortbatchBypass.Batch_Size__c));
            BatchByPassSettings__mdt batchBypass = BSF_Utilities.metaDataupdate(null,System.now(),false,'Opportunity_Team_Sync_Batch');//HRP-10890
        }
        
        if(this.recordType == BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
        {
            if(!test.isRunningTest())
            {
                Database.executebatch(new skedCollectionsZipCodeBatch(),200);
            }
        }
    }          
}