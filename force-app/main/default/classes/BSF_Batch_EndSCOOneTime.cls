global with sharing class BSF_Batch_EndSCOOneTime implements Database.Batchable<SObject> {
    
    /* ================= START ================= */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        Date endDate = Date.newInstance(4000, 12, 31);
        
        String query =
            'SELECT Id, Collection_Operation_Name__c, Collection_Operation_Code__c, ' +
            'Start_Date__c, End_Date__c, Zip_Code__c, Version_Key__c ' +
            'FROM Taxonomy__c ' +
            'WHERE RecordType.Name = \'Bio Collection BSF\' ' +
            'AND End_Date__c = :endDate';
        
        return Database.getQueryLocator(query);
    }
    
    /* ================= EXECUTE ================= */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        Date endDate = Date.newInstance(4000, 12, 31);
        try {
            
            List<BSF_Error_Log__c> insertErrorLog = new List<BSF_Error_Log__c>();
            
            /* ---------- TAXONOMY MAPS ---------- */
            Map<String, String> zipToCurrentTaxoKey = new Map<String, String>();
            Map<String, Date> zipToCurrentTaxoStart = new Map<String, Date>();
            Set<String> zipCodes = new Set<String>();
            
            for (Taxonomy__c taxo : (List<Taxonomy__c>) scope) {
                zipCodes.add(taxo.Zip_Code__c);
                zipToCurrentTaxoKey.put( taxo.Zip_Code__c, taxo.Zip_Code__c + taxo.Collection_Operation_Code__c);
                zipToCurrentTaxoStart.put(taxo.Zip_Code__c,taxo.Start_Date__c);
            }
            
            /* ---------- PREVIOUS TAXONOMY ---------- */
            Map<String, Taxonomy__c> zipToPrevTaxo = new Map<String, Taxonomy__c>();
            
            for (Taxonomy__c t : [
                SELECT Zip_Code__c, Start_Date__c, End_Date__c, Collection_Operation_Code__c
                FROM Taxonomy__c
                WHERE RecordType.Name = 'Bio Collection BSF'
                AND Zip_Code__c IN :zipCodes
                AND End_Date__c != :endDate
            ]) {
                if (!zipToPrevTaxo.containsKey(t.Zip_Code__c)) {
                    zipToPrevTaxo.put(t.Zip_Code__c, t);
                }
            }
            
            /* ---------- COLLECTION TERRITORY ---------- */
            Map<String, Id> collKeyToId = new Map<String, Id>();
            Map<String, Id> collKeywithStartandEnddate = new Map<String, Id>();
            for (Collections_Territory__c coll : [
                SELECT Id, Zip__c, sked_End_Date__c,sked_Start_Date__c,
                Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c
                FROM Collections_Territory__c
                WHERE Zip__c IN :zipCodes
                AND sked_End_Date__c = :endDate
            ]) {
                if (coll.Zip__c != null &&
                    coll.Collection_Operation__r != null &&
                    coll.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c != null) {
                        //  External Key with zip, collection operation,startdate,enddate
                        collKeywithStartandEnddate.put(coll.Zip__c + coll.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+coll.sked_Start_Date__c+coll.sked_End_Date__c,coll.Id);
                        collKeyToId.put( coll.Zip__c + coll.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c, coll.Id);
                    }
            }
            
            /* ---------- SITE CO ---------- */
            List<sked__Location__c> siteLocation = [
                SELECT Id, sked_Zip_Code__c
                FROM sked__Location__c
                WHERE sked_Zip_Code__c IN :zipCodes
            ];
            
            List<sked_Site_Collection_Operation__c> siteCOList = [
                SELECT Id, sked_Site__c, sked_Site__r.sked_Zip_Code__c,
                sked_Start_Date__c, sked_End_Date__c,
                sked_Collections_Zip_Code__c,
                sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c
                FROM sked_Site_Collection_Operation__c
                WHERE sked_Site__r.sked_Zip_Code__c IN :zipCodes
                AND sked_Start_Date__c != NULL
                AND sked_End_Date__c != NULL
                ORDER BY sked_Site__r.sked_Zip_Code__c,
                sked_Site__c,
                sked_Start_Date__c ASC
            ];
            
            
            Map<Id, List<sked_Site_Collection_Operation__c>> siteToSCO = new Map<Id, List<sked_Site_Collection_Operation__c>>();
            
            for (sked_Site_Collection_Operation__c sco : siteCOList) {
                if (!siteToSCO.containsKey(sco.sked_Site__c)) {
                    siteToSCO.put(sco.sked_Site__c, new List<sked_Site_Collection_Operation__c>());
                }
                siteToSCO.get(sco.sked_Site__c).add(sco);
            }
            
            /* ---------- END DATING ---------- */
            List<sked_Site_Collection_Operation__c> recordsToUpdate =
                new List<sked_Site_Collection_Operation__c>();
            
            for (sked__Location__c s : siteLocation) {
                
                String zip = s.sked_Zip_Code__c;
                
                String currentTaxoKey = zipToCurrentTaxoKey.get(zip);
                Date currTaxoStart = zipToCurrentTaxoStart.get(zip);
                Taxonomy__c prevTaxo = zipToPrevTaxo.get(zip);
                
                String prevTaxoKey ;
                if(prevTaxo != null){
                    prevTaxoKey = prevTaxo.Zip_Code__c + prevTaxo.Collection_Operation_Code__c;
                }
                List<sked_Site_Collection_Operation__c> zipSiteList = siteToSCO.get(s.Id);
                
                
                for (Integer i = 0; i< zipSiteList.size(); i++) {
                    
                    sked_Site_Collection_Operation__c current =  zipSiteList[i];
                    sked_Site_Collection_Operation__c nextRec = (i < zipSiteList.size() - 1) ? zipSiteList[i + 1] : null;
                    
                    
                    if (current.sked_End_Date__c != endDate) continue;
                    String currentKey = zip +current.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c;
                    String currentKeywithStartDateandEndDate =  zip +current.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+current.sked_Site__c+current.sked_End_Date__c;
                    
                    if (currentKey != currentTaxoKey) {
                        
                        if (nextRec != null) {
                            current.sked_End_Date__c =
                                nextRec.sked_Start_Date__c.addDays(-1);
                        }
                        else if (prevTaxo != null && currentKey == prevTaxoKey) {
                            current.sked_End_Date__c = prevTaxo.End_Date__c;
                        }
                        else {
                            if (currTaxoStart != null && current.sked_Start_Date__c <= currTaxoStart) {
                                current.sked_End_Date__c =
                                    currTaxoStart.addDays(-1);
                            }
                            else{
                                BSF_Error_Log__c log =
                                    BSF_Utilities.getErrorLog('Endating SCO','BSF_Batch_EndSCOOneTime', 'Execute', 'Error', 'Issue in Endating SCO of current Id'+current.Id,'Error');
                                insertErrorLog.add(log);
                            }
                        }
                        recordsToUpdate.add(current);
                    }
                    else if (nextRec != null && currentKey == currentTaxoKey) {
                        current.sked_End_Date__c =  nextRec.sked_Start_Date__c.addDays(-1);
                        recordsToUpdate.add(current);
                    }
                    ///
                    else if(current.sked_Collections_Zip_Code__c == null && collKeywithStartandEnddate.containsKey(currentKeywithStartDateandEndDate))
                    {
                        current.sked_Collections_Zip_Code__c =collKeywithStartandEnddate.get(currentKeywithStartDateandEndDate);
                        recordsToUpdate.add(current);
                    }
                    
                    else if (nextRec == null && current.sked_Collections_Zip_Code__c == null &&
                             collKeyToId.containsKey(currentKey)) {
                                 
                                 current.sked_Collections_Zip_Code__c =collKeyToId.get(currentKey);
                                 recordsToUpdate.add(current);
                             }
                    
                    else if (nextRec == null && current.sked_Collections_Zip_Code__c == null &&
                             !collKeyToId.containsKey(currentKey)) {
                                 
                                 BSF_Error_Log__c log = BSF_Utilities.getErrorLog('Endating SCO','BSF_Batch_EndSCOOneTime', 'Execute', 'Error', 'could not find the matched external key in collection zipcode'+current.Id,'Error');
                                 insertErrorLog.add(log);
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
            Database.insert(
                new List<BSF_Error_Log__c>{
                    BSF_Utilities.createBsfErrorLogForExceptions(
                        ex,
                        'BSF_Batch_EndCollectionandSCOOneTime',
                        'Execute',
                        'Error',
                        'Batch failed',
                        'sked_Site_Collection_Operation__c',
                        null
                    )
                        },
                false
            );
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}