/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 07/01/2026                     Harika Bolisetti                 This batch is created part of HRP-15920
*/

global with sharing class BSF_Batch_EndCollectionZipOneTime implements Database.Batchable<SObject> {

     //Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query;
        
        Date endDate = Date.newInstance(4000, 12, 31);
        query =
    'SELECT Id, Collection_Operation_Name__c, Collection_Operation_Code__c, ' +
    'Start_Date__c, End_Date__c, Zip_Code__c, Version_Key__c ' +
    'FROM Taxonomy__c ' +
    'WHERE RecordType.Name = \'Bio Collection BSF\' ' +
      'AND End_Date__c = :endDate';
 
        return Database.getQueryLocator(query);
    }
    
    
    // EXECUTE
    
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        Date endDate = Date.newInstance(4000, 12, 31);
        
        try {
            List<BSF_Error_Log__c> insertErrorLog = new List<BSF_Error_Log__c>();
            Map<String, String> zipToCurrentTaxoExtKey = new Map<String, String>();
            Set<String> zipCodes = new Set<String>();
            Map<String, Date> zipToCurrentTaxoStartDate= new Map<String, Date>();
            
            for (Taxonomy__c taxo : (List<Taxonomy__c>)scope) {
                zipCodes.add(taxo.Zip_Code__c);
                zipToCurrentTaxoExtKey.put(taxo.Zip_Code__c, taxo.Zip_Code__c + taxo.Collection_Operation_Code__c);
                zipToCurrentTaxoStartDate.put(taxo.Zip_Code__c,taxo.Start_Date__c);
            }
            
            /* ===============================
               STEP 2: Fetch previous Taxonomy per Zip
            =============================== */
            Map<String, Taxonomy__c> zipToPrevTaxo = new Map<String, Taxonomy__c>();
            
            for (Taxonomy__c prevTaxo : [
                SELECT Id, Zip_Code__c, Start_Date__c, End_Date__c,
                Collection_Operation_Code__c, Version_Key__c
                FROM Taxonomy__c
                WHERE RecordType.Name = 'Bio Collection BSF'
                AND Zip_Code__c IN :zipToCurrentTaxoExtKey.keySet() AND End_Date__c !=:endDate
                
            ]) {
                if (!zipToPrevTaxo.containsKey(prevTaxo.Zip_Code__c)) {
                    zipToPrevTaxo.put(prevTaxo.Zip_Code__c, prevTaxo);
                }
            }
            
            /* ===============================
              STEP 3: Fetch Collections Territories
              =============================== */
            List<Collections_Territory__c> collList = [
                SELECT Id, Zip__c, Collection_Operation__c,
                sked_Start_Date__c, sked_End_Date__c,Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c
                FROM Collections_Territory__c
                WHERE Zip__c IN :zipToCurrentTaxoExtKey.keySet()
                AND sked_Start_Date__c != NULL
                AND sked_End_Date__c != NULL
                ORDER BY Zip__c, sked_Start_Date__c ASC
            ];
            
            /*Group by Zip*/
            
            Map<String, List<Collections_Territory__c>> zipToCollMap =  new Map<String, List<Collections_Territory__c>>();
            
            for (Collections_Territory__c ct : collList) {
                if (!zipToCollMap.containsKey(ct.Zip__c)) {
                    zipToCollMap.put(ct.Zip__c, new List<Collections_Territory__c>());
                }
                zipToCollMap.get(ct.Zip__c).add(ct);
            }
            
            /* Apply end-dating logic*/
            List<Collections_Territory__c> recordsToUpdate = new List<Collections_Territory__c>();
            
            for (String zip : zipToCollMap.keySet()) {
                
                String currentTaxoExternalKey = zipToCurrentTaxoExtKey.get(zip);
                
                Taxonomy__c prevTaxo = zipToPrevTaxo.get(zip);
                String prevTaxoExternalKey;
                if(prevTaxo!=null){
                    prevTaxoExternalKey = prevTaxo.Zip_Code__c + prevTaxo.Collection_Operation_Code__c;
                }
                List<Collections_Territory__c> zipCollList = zipToCollMap.get(zip);
                
                for (Integer i = 0; i < zipCollList.size(); i++) {
                    
                    Collections_Territory__c current = zipCollList[i];
                    Collections_Territory__c nextRec = (i < zipCollList.size() - 1) ? zipCollList[i + 1] : null;
                    
                    if (current.sked_End_Date__c != endDate) continue;
                    
                    String currentKey = current.Zip__c + current.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c;
                    
                    
                    // Case 1: Not current taxonomy
                    if (currentKey != currentTaxoExternalKey) {
                        
                        if (nextRec != null) {  
                            current.sked_End_Date__c = nextRec.sked_Start_Date__c.addDays(-1);
                        }
                        else if (prevTaxo != null && currentKey == prevTaxoExternalKey) {
                            current.sked_End_Date__c = prevTaxo.End_Date__c;
                        }
                        
                        else {
                            Date currTaxoStart = zipToCurrentTaxoStartDate.get(zip);
                            if (currTaxoStart != null && current.sked_Start_Date__c <= currTaxoStart) {
                                
                                current.sked_End_Date__c =currTaxoStart.addDays(-1);
                            }
                            
                            else{
                                BSF_Error_Log__c log = BSF_Utilities.getErrorLog('Endating Collection Zip code','BSF_Batch_EndCollectionandSCOOneTime', 'Execute', 'Error', 'Issue in Endating Collection Zip code of current Id'+current.Id,'Error');
                                insertErrorLog.add(log);
                            }
                            
                        }
                        
                        recordsToUpdate.add(current);
                    }
                    
                    // Case 2: Current taxonomy but has next record
                    else if (nextRec != null && currentKey == currentTaxoExternalKey) {
                        current.sked_End_Date__c =  nextRec.sked_Start_Date__c.addDays(-1);
                        recordsToUpdate.add(current);
                    }
                }
            }
            
            if (!recordsToUpdate.isEmpty()) {
                Database.update(recordsToUpdate, false);
            }
            if (!insertErrorLog.isEmpty()) {
             Database.insert(insertErrorLog, false);
          }
            
        } catch (Exception ex) {
            
            
            Database.insert(new List<BSF_Error_Log__c>{
                BSF_Utilities.createBsfErrorLogForExceptions(
                    ex,
                    'BSF_Batch_EndCollectionZipandSCO',
                    'Execute',
                    'Error',
                    'Error while end-dating Collection Zipcode.',
                    'Collections_Territory__c',
                    null
                )
                    }, false);
        }
    }
    
    global void Finish(Database.BatchableContext bc)
    {
    }
}