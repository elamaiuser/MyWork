/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 03/12/2024                      Harika Bolisetti            Logic for HRP-14434//Taxo Run Chaining in finish method
*
*/
global class BSF_Batch_PopulateCORegion implements Database.Batchable<sObject>,Database.Stateful
{
    global date createdDate;
    global Decimal taxVer;
    global boolean allowChaining = false;//HRP-14434
    global BSF_Batch_PopulateCORegion (Date createdDate, Decimal taxVer)
    {
        this.createdDate = createdDate;
        this.taxVer = taxVer;
    }
    //HRP-14434
    global BSF_Batch_PopulateCORegion (Date createdDate, Decimal taxVer,boolean allowChaining)
    {
        this(createdDate,taxVer);
        this.allowChaining = allowChaining;
    }
    global BSF_Batch_PopulateCORegion ()
    {
        system.debug('BSF_Batch_PopulateCORegion batch is called');
    }
    
    global Database.queryLocator start(Database.BatchableContext BC) {
        //TODO: need to add filters, need to email somebody to clarify
        //BSF_setting__c setting = BSF_setting__c.getOrgDefaults();
        
        try {//HRP-14434
            system.debug('entered batch');
            
            String taxList = 'SELECT Id, End_Date__c, Start_Date__c, Zip_Code__c,Division_Code__c,Division_Name__c,'+
                'DS_Region_Code__c,DS_Region_Name__c,District_Code__c,District_Name__c,'+
                'Collection_Operation_Code__c,Collection_Operation_Key__c,Collection_Operation_Name__c,'+
                'skedulo_region_name__c,Time_Zone__c,Version_Key__c,recordtypeid FROM Taxonomy__c'+
                ' WHERE RecordType.Name = \'Bio Collection BSF\'';
            if(createdDate == null && taxVer == null)
            {
                taxList = taxList + ' AND CREATEDDATE = TODAY';
            }
            else if(createdDate != null && taxVer != null)
            {
                date nextDay = createdDate+1;
                taxList = taxList +' AND (CREATEDDATE >=:createdDate and CREATEDDATE < :nextDay) AND Version_Key__c = :taxVer';
            }
            else if(createdDate != null)
            {
                date nextDay = createdDate+1;
                taxList = taxList + ' AND (CREATEDDATE >=:createdDate and CREATEDDATE < :nextDay)';
            }
            else if (taxVer != null)
            {
                taxList = taxList +' AND Version_Key__c = :taxVer';
            }
            
            taxList = taxList +' ORDER BY Id ASC';
            system.debug(taxList);             
            //HRP-14434
            //Capture start method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='BSF_Batch_PopulateCORegion',Method__c='start',Type__c='Success',
                                                             Error_Description__c='Batch Process Started',Error_Description_Long__c= taxList);
            errorLogList.add(errorLog);
            // insert errorLog;
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Start','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return Database.getqueryLocator(taxList);
        } catch (Exception e) { //HRP-14434
            System.debug('Error in start method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_PopulateCORegion', 'Start', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            return null;
        }
    }
    global void execute(Database.BatchableContext BC, List<Taxonomy__c> taxonomyRecords) 
    {
        
        try {//HRP-14434
            system.debug('taxonomyRecords'+taxonomyRecords);
            map<string,sked_Territory__c> divisionUpsertMap = new map<string,sked_Territory__c>();
            map<string,sked_Territory__c> regionUpserMap= new map<string,sked_Territory__c>();
            map<string,sked_Territory__c> districtUpserMap= new map<string,sked_Territory__c>();
            map<string,Biomed_Collection_Op_Center__c> coUpsertMap = new map<string,Biomed_Collection_Op_Center__c>();
            map<string,sked_Territory_Collection_Operation__c> terrCollOpMap = new map<string,sked_Territory_Collection_Operation__c>();
            map<string,Sked__Region__c> skRegionUpsertmap = new map<string,Sked__Region__c>();
            //HRP-14434
            //Check the existing records of Tax run records with status = 'pending' or 'completed'
            List<Taxonomy_Run__c> taxoRunList = new List<Taxonomy_Run__c>();
            for (Taxonomy_Run__c txrn : [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c FROM Taxonomy_Run__c  WHERE Taxo_Record_Type__c = :BSF_Constants.BIO_COLLECTION_RECORD_TYPE   
                                         AND Future_Version_Number__c = :taxVer 
                                         AND Status__c IN ('Pending', 'Completed')]) {
                                             txrn.Status__c = 'Processing';
                                             txrn.Processing_Start__c = System.now();
                                             taxoRunList.add(txrn);
                                         }
            
            if (!taxoRunList.isEmpty()) 
            {
                
                Database.SaveResult[] updateResults = Database.update(taxoRunList, false);
                Taxo_Utilities.logErrors(updateResults, 'Taxonomy Run', 'BSF_Batch_PopulateCORegion', 'Finish', 'Error',
                                         'Error occurred while updating the Taxonomy Run Record',taxoRunList[0].Taxo_Record_Type__c,taxoRunList[0].Future_Version_Number__c);
            }    
        
            for(Taxonomy__c tx: taxonomyRecords)
            {
                divisionUpsertMap.put('Bio_Collection_BSF'+tx.Division_Code__c,(createTerritory(tx,'Division',tx.Division_Code__c,tx.Division_Name__c,null)));
                
                regionUpserMap.put('Bio_Collection_BSF'+tx.DS_Region_Code__c,(createTerritory(tx,'ARC Region',tx.Division_Code__c+'_'+tx.DS_Region_Code__c,tx.DS_Region_Name__c,'Bio_Collection_BSF_Division_'+tx.Division_Code__c)));
                
                districtUpserMap.put('Bio_Collection_BSF'+tx.District_Code__c,(createTerritory(tx,'District',tx.Division_Code__c+'_'+tx.DS_Region_Code__c+'_'+tx.District_Code__c,tx.District_Name__c,'Bio_Collection_BSF_ARC Region_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c)));
                
                coUpsertMap.put('Bio_Collection_BSF' + tx.Collection_Operation_Code__c,(createCollectionOperation(tx,'Bio_Collection_BSF_District_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c+'_'+tx.District_Code__c)));
                
                sked_Territory__c currentDistrict = districtUpserMap.get('Bio_Collection_BSF'+tx.District_Code__c);
                Biomed_Collection_Op_Center__c currentCollOpp = coUpsertMap.get('Bio_Collection_BSF' + tx.Collection_Operation_Code__c);
                terrCollOpMap.put('Bio_Collection_BSF'+tx.District_Code__c+tx.Collection_Operation_Code__c,createTerritoryCollOp(currentDistrict,currentCollOpp));
                
                skRegionUpsertmap.put('Bio_Collection_BSF' + tx.Collection_Operation_Code__c+tx.Time_Zone__c,(createRegion(tx,'Bio_Collection_BSF_' + tx.Collection_Operation_Code__c,districtUpserMap.get('Bio_Collection_BSF'+tx.District_Code__c).External_Id__c)));
            }
            
            Schema.SObjectField extField = sked_Territory__c.Fields.External_Id__c;
            
            //Territory records--------
            Database.UpsertResult[] divisionUpsert = Database.upsert(startDateDecision(divisionUpsertMap.values()), extField, false);
            
            Database.UpsertResult[] regionUpsert = Database.upsert(startDateDecision(regionUpserMap.values()), extField, false);
            
            list<sked_Territory__c> districtList = startDateDecision(districtUpserMap.values());
            Database.UpsertResult[] districtUpsert = Database.upsert(districtList, extField, false);
            //Collection operation setup--------
            map<string,sked_Territory__c> exIdTerrMapDistrict = new map<string,sked_Territory__c>();
            for(sked_Territory__c terr:districtList)
            {
                exIdTerrMapDistrict.put(terr.External_Id_BackEnd__c,terr);
            }
            map<string,Biomed_Collection_Op_Center__c> exIdCollOpMap = new map<string,Biomed_Collection_Op_Center__c>();
            for(Biomed_Collection_Op_Center__c cop:coUpsertMap.values())
            {
                string extId = cop.sked_Territory__r.External_Id__c;
                sked_Territory__c districtTerr = exIdTerrMapDistrict.get(extId);
                
                if(districtTerr!=null)
                {
                    cop.sked_Territory__r=new sked_Territory__c(External_Id__c=districtTerr.External_Id__c);
                }
                exIdCollOpMap.put(cop.External_Id__c,cop);
                
            }
            //Collection operation------------
            extField = Biomed_Collection_Op_Center__c.Fields.External_Id__c;
            Database.UpsertResult[] coUpsert = Database.upsert(coUpsertMap.values(),extField, false);
            //TerritoryCollection operation setup----------
            for(sked_Territory_Collection_Operation__c terrCop:terrCollOpMap.values())
            {
                string extId = terrCop.sked_Collection_Operation__r.External_Id__c;
                Biomed_Collection_Op_Center__c collecTerr= exIdCollOpMap.get(extId);
                terrCop.sked_Collection_Operation__r=new Biomed_Collection_Op_Center__c(External_Id__c=collecTerr.External_Id__c);
                terrCop.sked_Territory__r = new sked_Territory__c(External_Id__c = collecTerr.sked_Territory__r.External_Id__c);
                terrCop.sked_External_ID__c = collecTerr.sked_Territory__r.External_Id__c+'__'+collecTerr.Biomed_Collection_Op_Code_Center_ID__c;
            }
            
            //TerritoryCollection operation------------
            extField = sked_Territory_Collection_Operation__c.Fields.sked_External_ID__c;
            Database.UpsertResult[] terrCollOpUpsert = Database.upsert(terrCollOpMap.values(),extField, false);
            for(Database.upsertResult result:terrCollOpUpsert)
            {
                if(!result.isSuccess())
                {
                    system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: '+ result.isCreated());
                }
            }
        
            //Skedulo region setup------------
            for(Sked__Region__c sReg:skRegionUpsertmap.values())
            {
                string extId = sReg.sked_Biomed_Collection_Op_Center__r.External_Id__c;
                Biomed_Collection_Op_Center__c collecTerr= exIdCollOpMap.get(extId);
                sReg.sked_Biomed_Collection_Op_Center__r=new Biomed_Collection_Op_Center__c(External_Id__c=collecTerr.External_Id__c);
                sReg.sked_Territory__r = new sked_Territory__c(External_Id__c=collecTerr.sked_Territory__r.External_Id__c);
            }
            //Skedulo region------------
            extField = Sked__Region__c.Fields.sked_External_Id__c;
            Database.UpsertResult[] skRegionUpsert = Database.upsert(skRegionUpsertmap.values(),extField, false);
            //error logs-------
            BSFPortfolioHelper bsfHelp = new BSFPortfolioHelper();
            bsfHelp.insertErrors(divisionUpsert,'Division Territory Upsert');
            bsfHelp.insertErrors(regionUpsert,'Region Territory Upsert');
            bsfHelp.insertErrors(districtUpsert,'District Territory Upsert');
            bsfHelp.insertErrors(coUpsert,'Collection Operation Upsert');
            bsfHelp.insertErrors(terrCollOpUpsert,'Territory Collection Operation Upsert');
            bsfHelp.insertErrors(skRegionUpsert,'skedule Region Upsert');
        } catch (Exception e) { //HRP-14434
            System.debug('Error in execute method: ' + e.getMessage());
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_PopulateCORegion', 'Execute', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
        
    }
    global void finish(Database.BatchableContext BC) 
    {
        //HRP-14434
        try {
            
            //Capture finish method entry in Error Log
            List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c='Taxo Run - Collection',ApexClass__c='BSF_Batch_PopulateCORegion',Method__c='finish',
                                                             Type__c='Success',Error_Description__c='Batch Process Completed' ,
                                                             Error_Description_Long__c='');
            errorLogList.add(errorLog);
            //insert errorLog;
            Database.SaveResult[] insertResult = Database.insert(errorLogList, false);
            Taxo_Utilities.logErrors(insertResult,'Taxonomy Run','BSF_Batch_BSFPortfolio','Finish','Error',
                                     'Error occurred while inserting the error Record',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
            Taxonomy__c taxFinal =[SELECT Id,CreatedDate FROM Taxonomy__c
                                   WHERE RecordType.Name = 'Bio Collection BSF' ORDER BY Id Desc LIMIT 1];
            Integer batchSize = Taxo_Utilities.getBatchSize(BSF_Constants.BIO_COLLECTION_RECORD_TYPE, 'BSF_Batch_PopulateCORegion');   
            BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(this.taxVer,BSF_Constants.BIO_COLLECTION_RECORD_TYPE,false,null,null,this.allowChaining);
            database.executebatch(batch,batchSize);
                Integer x = 1/0; // This will throw a "System.MathException: Division by 0"
            /*if(!test.isRunningTest())
{
Database.executebatch(new skedCollectionsZipCodeBatch(),200);
}*/
        } catch (Exception e) { //HRP-14434
            
            Taxo_Utilities.logErrorForException(e, 'BSF_Batch_PopulateCORegion', 'Finish', e.getMessage(), e.getMessage(), 'Taxonomy_Run__c',BSF_Constants.BIO_COLLECTION_RECORD_TYPE,taxVer);
        }
    }
    
    
    public static sked_Territory__c createTerritory(Taxonomy__c tx,String recordTypeName,string Code,string name,String ParentId)
    {
        
        Id recordTypeId = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        system.debug(Code);
        sked_Territory__c territory = new sked_Territory__c();
        territory.External_Id__c='Bio_Collection_BSF_'+recordTypeName+'_'+Code+'_'+tx.Start_Date__c;
        territory.External_Id_BackEnd__c ='Bio_Collection_BSF_'+recordTypeName+'_'+Code;
        system.debug(territory.External_Id__c);
        territory.Name = name;
        territory.RecordTypeId  = recordTypeId;
        territory.Start_Date__c = tx.Start_Date__c;
        territory.End_Date__c = tx.End_Date__c;
        if(ParentId!=null)
            territory.sked_Parent__r= new sked_Territory__c(External_Id__c=parentId+'_'+tx.Start_Date__c);
        return territory;
    }
    
    public static Biomed_Collection_Op_Center__c createCollectionOperation(Taxonomy__c Tx,String ParentId)
    {
        
        Biomed_Collection_Op_Center__c co = new Biomed_Collection_Op_Center__c();
        co.Biomed_Collection_Op_Code_Center_ID__c =tx.Collection_Operation_Code__c;
        co.Collection_Operation_ID__c=string.valueof(tx.Collection_Operation_Key__c);
        co.Name=tx.Collection_Operation_Name__c;
        co.External_Id__c = 'Bio_Collection_BSF_' + tx.Collection_Operation_Code__c;
        if(parentId != null)
            co.sked_Territory__r=new sked_Territory__c(External_Id__c=parentId);
        co.sked_Lunch_Break_Duration_Fixed_Site__c='30';
        co.sked_Lunch_Break_Duration_Mobile__c='30';
        return co;
     
       

    }
    
    public static sked_Territory_Collection_Operation__c createTerritoryCollOp(sked_Territory__c district,Biomed_Collection_Op_Center__c collOp)
    {
      
            sked_Territory_Collection_Operation__c terrCollOpp = new sked_Territory_Collection_Operation__c();
            terrCollOpp.sked_Start_Date__c = district.Start_Date__c;
            terrCollOpp.sked_End_Date__c = district.End_Date__c;
            terrCollOpp.sked_External_ID__c = district.External_Id__c+'__'+collOp.Biomed_Collection_Op_Code_Center_ID__c;
            terrCollOpp.sked_Territory__r = new sked_Territory__c(External_Id__c = district.External_Id__c);
            terrCollOpp.sked_Collection_Operation__r = new Biomed_Collection_Op_Center__c(External_Id__c=collOp.External_Id__c);
            system.debug('sked_Territory_Collection_Operation__c'+terrCollOpp);
            return terrCollOpp;
     
       
    }
    public static Sked__Region__c createRegion(Taxonomy__c Tx,String parentIdCollOp,string parentIdTerr)
    {
     
            Sked__Region__c region = new Sked__Region__c();
            region.Name =tx.skedulo_region_name__c;
            region.sked__Description__c=tx.skedulo_region_name__c;
            region.sked__Timezone__c=tx.Time_Zone__c;
            region.sked_Biomed_Collection_Op_Center__r=new Biomed_Collection_Op_Center__c(External_Id__c=parentIdCollOp);
            region.sked_External_Id__c = 'Bio_Collection_BSF_' + tx.Collection_Operation_Code__c+'_'+tx.Time_Zone__c;
            region.sked_Territory__r = new sked_Territory__c(External_Id__c=parentIdTerr);
            region.sked__Timezone__c=tx.Time_Zone__c;
            
            return region;
      
    }
    
    
    public static list<sked_Territory__c> startDateDecision (list<sked_Territory__c> territories)
    {
           set<string> exIdSet = new set<string>();
            for(sked_Territory__c terr :territories)
            {
                exIdSet.add(terr.External_Id_BackEnd__c);
                if(terr.sked_Parent__r.External_Id__c != null)
                {
                    system.debug('parent'+terr.sked_Parent__r.External_Id__c.substringBeforeLast('_'));
                    exIdSet.add(terr.sked_Parent__r.External_Id__c.substringBeforeLast('_'));
                }
            }
            
            list<sked_Territory__c> existingTerritoryList = [select id,Name,External_Id__c,External_Id_BackEnd__c,Start_Date__c,End_Date__c,sked_Parent__c,sked_Parent__r.External_Id__c from sked_Territory__c where External_Id_BackEnd__c IN:exIdSet order by CreatedDate desc];
            system.debug('existingTerritoryList'+existingTerritoryList);
            map<string,sked_Territory__c> exIdExTerrMap = new map<string,sked_Territory__c>();
            for(sked_Territory__c terr :existingTerritoryList)
            {
                if(!exIdExTerrMap.keyset().contains(terr.External_Id_BackEnd__c))
                {
                    system.debug('territories '+terr);
                    exIdExTerrMap.put(terr.External_Id_BackEnd__c,terr);
                }
            }
        
        
            for(sked_Territory__c terr :territories)
            {
                string parentExtKey;
                if(terr.sked_Parent__r.External_Id__c != null)
                    parentExtKey = terr.sked_Parent__r.External_Id__c.substringBeforeLast('_');
                if(exIdExTerrMap != null && exIdExTerrMap.get(terr.External_Id_BackEnd__c) != null)
                {
                    sked_Territory__c exTerrPortfolio = exIdExTerrMap.get(terr.External_Id_BackEnd__c);
                    if(exIdExTerrMap.keyset().contains(terr.External_Id_BackEnd__c) && ((exTerrPortfolio.start_date__c != terr.start_date__c &&
                                                                                         terr.start_date__c <= exTerrPortfolio.End_date__c && terr.start_date__c >= exTerrPortfolio.start_date__c) || terr.start_date__c == exTerrPortfolio.End_date__c+1) )
                    {
                        system.debug('territories '+terr);
                        terr.start_date__c = exTerrPortfolio.start_date__c;
                        terr.External_Id__c = exTerrPortfolio.External_Id__c;
                        if(exTerrPortfolio.sked_Parent__c!=null && exTerrPortfolio.sked_Parent__r.External_Id__c != null)
                            terr.sked_Parent__r = new sked_Territory__c(External_Id__c=exTerrPortfolio.sked_Parent__r.External_Id__c);
                    }
                    else if(exIdExTerrMap.keyset().contains(parentExtKey))
                    {
                        system.debug('Its here');
                        sked_Territory__c parentTerr = exIdExTerrMap.get(parentExtKey);
                        terr.sked_Parent__r = new sked_Territory__c(External_Id__c=parentTerr.External_Id__c);
                    }
                }
                else if(exIdExTerrMap.keyset().contains(parentExtKey))
                {
                    system.debug('Its here');
                    sked_Territory__c parentTerr = exIdExTerrMap.get(parentExtKey);
                    terr.sked_Parent__r = new sked_Territory__c(External_Id__c=parentTerr.External_Id__c);
                }
                system.debug('territories '+territories);
            }
            return territories;
       
    }
}