/*
* Modification Log
* Date					     Developer Name			     Comments
* *******************************************************************************************************************************************************************************************************
* 11/26/2024                  Balaji N                   Logic for HRP-13866 Method:getexternalKeyTaxonomyMap System.Label.NO_SBPM_ABM in place of hard coded value
*********************************************************************************************************************************************************************************************************
*/
public class BSF_Batch_TaxonomyEndDateHelper
{
    public static void endDateTaxonomy(
        list<taxonomy__c> newVerTax,
        list<taxonomy__c> oldVerTax, 
        Set<String> allNewTaxoVerExternalKeySet,
        Set<String> allNewTaxoVerTcoKeySet)
    {
        List<sked_Territory_Collection_Operation__c> toUpdateTcoList = new List<sked_Territory_Collection_Operation__c>();
        
        set<id> taxRecTypeSet = new set<id>();
        Decimal versionKey;
        //map of current/old taxonomy ID and list of external keys
        map<String,taxonomy__c> taxIdExternalKeysMap = getexternalKeyTaxonomyMap (oldVerTax);
        //system.debug('taxIdExternalKeysMap '+taxIdExternalKeysMap);
        set<string> externalKeySet = new set<string>();
        externalKeySet.addAll(taxIdExternalKeysMap.keyset());
        //map of future/new taxonomy ID and list of external keys
        map<String,taxonomy__c> newTaxIdExternalKeysMap = getexternalKeyTaxonomyMap (newVerTax);
        set<string> externalKeySetNew = new set<string>();
        externalKeySetNew.addAll(newTaxIdExternalKeysMap.keyset());
      
        //related bsf portfolio of current/old taxonomies
        List<bsf_Portfolio__c> bsfPortfolioList = [SELECT Id, External_Key__c,External_Key_BackEnd__c , Portfolio_Type__c, Taxonomy_Type__c, Territory_Portfolio__c,
                                                   Parent_Portfolio__c, Start_Date__c, End_Date__c, Is_Expired__c, Portfolio_Code__c, Portfolio_Name__c FROM BSF_Portfolio__c
                                                   where External_Key_BackEnd__c  IN:externalKeySet order by createdDate desc];
        //system.debug('bsfPortfolioList'+bsfPortfolioList);
        //BSF Portfolio process
        if(!bsfPortfolioList.isEmpty())
        {
            map<string,bsf_Portfolio__c> bsfIdBSfMap = new map<string,bsf_Portfolio__c>();
            for(bsf_Portfolio__c bsf:bsfPortfolioList)
            {
                if(!bsfIdBSfMap.keyset().contains(bsf.External_Key_BackEnd__c))
                    bsfIdBSfMap.put(bsf.External_Key_BackEnd__c ,bsf);
            }
            map<id,bsf_Portfolio__c> bsfPortfolioToUpdateMap = new map<id,bsf_Portfolio__c>();
            List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
            //system.debug('bsfIdBSfMap'+bsfIdBSfMap);
            for(string exKey: taxIdExternalKeysMap.keyset())
            {
                Taxonomy__c tx = new Taxonomy__c();
                tx = taxIdExternalKeysMap.get(exKey);
                if(!externalKeySetNew.contains(exKey))
                {
                    //system.debug('exKey '+exKey);
                    bsf_Portfolio__c bsf = new bsf_Portfolio__c ();
                    bsf = bsfIdBSfMap.get(exKey);
                    //system.debug('bsf70 '+bsf);
                    if(bsf != NULL && tx.End_Date__c != bsf.End_Date__c && bsf.Start_Date__c < bsf.End_Date__c)
                    {
                        bsf.End_Date__c = tx.End_Date__c;
                        bsfPortfolioToUpdateMap.put(bsf.id,bsf);
                        BSF_Error_Log__c log1 = BSF_Utilities.getErrorLog('Create Portfolio', 'endaate', 'endate helper', 'Debug Log','No Error - Platform Event log', 'BSFId: '+ string.valueof(bsf.id)+'_'+bsf.End_Date__c+' '+ 'TX id: '+ string.valueof(tx.id)+'_'+tx.End_Date__c);
                        logList.add(log1);
                        bsfPortfolioToUpdateMap.put(bsf.id,bsf);
                    }
                }
            }
            if(!logList.isEmpty())
            {
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            if(!bsfPortfolioToUpdateMap.values().isEmpty())
            {
                Database.saveResult [] results = database.update(bsfPortfolioToUpdateMap.values(),false);
                List<BSF_Error_Log__c> logList1 = BSF_Utilities.createErrorLog(results, 'Create Portfolio','Tax endate helper','createDMRecords','Error','Error in upserting Bsf portfolio ');
                InsertBsfErrorLog.insertBsfErrors(logList1);
            }
        }
        system.debug('externalKeySet '+externalKeySet);
        //Calling for HRP-15653 new fix
        endDateTerritoriesBatchSafe(
            taxIdExternalKeysMap,
            externalKeySet,
            allNewTaxoVerExternalKeySet,
            allNewTaxoVerTcoKeySet);

    }
    //Method returns map of taxonomy id and list of external keys of BSFPortfolios
    public static map<String,taxonomy__c> getexternalKeyTaxonomyMap(list<taxonomy__c> taxonomyList)
    {
        map<String,taxonomy__c> taxIdExternalKeysMap = new map<String,taxonomy__c>();
        for(Taxonomy__c tx:taxonomyList)
        {
            //system.debug('tcxc'+tx.id);
            string recordtypename = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosById().get(tx.recordtypeid).getname();
            if(recordtypename == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
            {
                if(tx.ABM_Name__c != null && tx.ABM_Name__c != 'NA' && !tx.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM))//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
                {
                    externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.ABM_Code__c,'_'+tx.DRD_Territory_Code__c});
                }
                else
                {
                    externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.DRD_Territory_Code__c});
                }
            }
            else if(recordtypename == BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.District_Code__c,'_'+tx.Collection_Operation_Code__c,'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE
                    || recordtypename == BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Portfolio_Code__c});
            }
            else if(recordtypename == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
            {
                externalKeyfinder(recordtypename,taxIdExternalKeysMap,tx,new List<string>{'_'+tx.Division_Code__c,'_'+tx.DS_Region_Code__c,'_'+tx.Team_Code__c,'_'+tx.Supervisor_Code__c,'_'+tx.DRD_Territory_Code__c});
            }
            else if(recordtypename == BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
            {
                externalKeyfinder(
                    recordtypename,
                    taxIdExternalKeysMap,
                    tx,
                    new List<string>{
                        '_'+tx.Division_Code__c,
                        '_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c,
                        '_'+tx.Division_Code__c+'_'+tx.DS_Region_Code__c+'_'+tx.District_Code__c});
            }
        }
        return taxIdExternalKeysMap;
    }
    // Method returns a list of external key for a given taxonomy
    public static void externalKeyfinder (string recordtypeName,map<String,taxonomy__c> taxIdExternalKeysMap,Taxonomy__c tx,list<string> codeString)
    {
        List<string> externalKeyList = new list<string>();
        list<string> bioCollTerrRecType = new list<string>{'Division','ARC Region','District'};
        for(string s : codeString)
        {
            if(externalKeyList.isEmpty())
            {
                if(recordtypeName != BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
                {
                    externalKeyList.add(recordtypeName+s);
                    taxIdExternalKeysMap.put(recordtypeName+s,tx);
                }
                else
                {
                    externalKeyList.add('Bio_Collection_BSF'+'_'+bioCollTerrRecType[0]+s);
                    taxIdExternalKeysMap.put('Bio_Collection_BSF'+'_'+bioCollTerrRecType[0]+s,tx);
                }
            }
            else
            {
                string temp;
                if(recordtypeName != BSF_Constants.BIO_COLLECTION_RECORD_TYPE)
                {
                    temp = externalKeyList.get(externalKeyList.size()-1)+s;
                }
                else
                {
                    temp ='Bio_Collection_BSF'+'_'+bioCollTerrRecType[externalKeyList.size()]+s;
                }
                externalKeyList.add(temp);
                taxIdExternalKeysMap.put(temp,tx);
            }
            if(externalKeyList.size()==codeString.size() && (recordtypename == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE || recordtypename == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE))
            {
                //string splited = externalKeyList.get(externalKeyList.size()-1);
                //system.debug('splited_'+splited);
                externalKeyList.add('Account Specialist'+codeString[2]);
                taxIdExternalKeysMap.put('Account Specialist'+codeString[2],tx);
                ///system.debug('splited_'+externalKeyList[3]);
            }
        }
        //system.debug('HRP-15653 ====>>> taxIdExternalKeysMap : '+taxIdExternalKeysMap.size());
        //return externalKeyList;
    }
     
    //HRP-15653 Existing Logic Modified ->  TERRITORY END-DATING — Modified for Batching chunking
    private static void endDateTerritoriesBatchSafe(Map<String, Taxonomy__c> oldKeyToTaxMap,
                                                    Set<String> currentChunkOfOldTaxoExternalKeySet,
                                                    Set<String> allNewTaxoVerExternalKeySet,
                                                    Set<String> allNewTaxoVerTcoKeySet) {
        Set<id> territoryIdSet = new Set<id>();
        Set<id> territoryIdSetToBeUsedInTCOsEnding = new Set<id>();
        List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
        Set<string> terrIdSet = new Set<string>();
        if (currentChunkOfOldTaxoExternalKeySet.isEmpty()) {
            return;
        }
        //STEP 1: Fetch Territories (existing behavior)
        List<sked_Territory__c> terrList = [
            SELECT Id, Start_Date__c, End_Date__c,External_Id__c, External_Id_BackEnd__c
            FROM sked_Territory__c
            WHERE External_Id_BackEnd__c IN :currentChunkOfOldTaxoExternalKeySet
            and End_Date__c >=:System.today()
            ORDER BY CreatedDate DESC
        ];
        
        Map<String, sked_Territory__c> keyToTerritory = new Map<String, sked_Territory__c>();
        for (sked_Territory__c t : terrList) {
            if (!keyToTerritory.containsKey(t.External_Id_BackEnd__c)) {
                keyToTerritory.put(t.External_Id_BackEnd__c, t);
            }
            territoryIdSetToBeUsedInTCOsEnding.add(t.Id);
        }
        
        //STEP 2: END-DATE ONLY IF TERRITORY DOES NOT EXIST IN NEW VERSION AT ALL
        Map<Id, sked_Territory__c> terrToUpdateMap = new Map<Id, sked_Territory__c>();
        for (String terrKey : currentChunkOfOldTaxoExternalKeySet) {
            //FIX: batch-safe existence check
            if (allNewTaxoVerExternalKeySet.contains(terrKey)) {
                //Check For TCO updates
                continue;
            }
            sked_Territory__c terr = keyToTerritory.get(terrKey);
            Taxonomy__c oldTx = oldKeyToTaxMap.get(terrKey);
            if (terr == null || oldTx == null) {
                continue;
            }
            if ( (terr.Start_Date__c < oldTx.End_Date__c) && (terr.End_Date__c != oldTx.End_Date__c) ) {

                terr.End_Date__c = oldTx.End_Date__c;
                terrToUpdateMap.put(terr.Id, terr);
                terrIdSet.add(string.valueof(terr.id));
                BSF_Error_Log__c log1 = BSF_Utilities.getErrorLog('Create Portfolio', 'endaate', 'endate helper', 'Debug Log','No Error - Platform Event log', 'BSFId: '+ string.valueof(terr.id)+'_'+terr.End_Date__c+' '+ 'TX id: '+ string.valueof(oldTx.id)+'_'+oldTx.End_Date__c);
                logList.add(log1);
            }
        }
        List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(terrIdSet,'Create Oppty Team','createOpptyTeamMembersBasedOnOppties','EndDateBatch','Success','territoriesd updated are');
        if(!successList.isEmpty()){
            try {
                insert successList;
            }
            catch (exception e){
                system.debug('The exception in successList: '+e);
            }
        }
        if(!terrToUpdateMap.values().isEmpty()){
            // Database.update(toUpdate.values(), false);
            TriggerHandler.bypass('TerritoryTriggerHandler');
            Database.saveResult [] results;
            try {
                results = database.update(terrToUpdateMap.values(),false);
            } finally {
                TriggerHandler.clearBypass('TerritoryTriggerHandler');
            }
            List<BSF_Error_Log__c> logList1 = BSF_Utilities.createErrorLog(results, 'Populate Account Team','endDateTaxonomy','Endate_Territory','Error','Error in Endate_Territory');
            InsertBsfErrorLog.insertBsfErrors(logList1);
        }

        endDateTCOsBatchSafe(
            oldKeyToTaxMap,
            territoryIdSetToBeUsedInTCOsEnding,
            allNewTaxoVerTcoKeySet
        );
        
    } 
    /**
     * Generate TCO hierarchy keys for Bio Collection taxonomy
     * Format: Bio_Collection_BSF_District_<Div>_<Region>_<District>_<CO>
     */
    public static Set <String> getTcoExternalKeyTaxonomy(List<Taxonomy__c> taxList) {

        //Map<String, Taxonomy__c> keyToTaxMap = new Map<String, Taxonomy__c>();
        Set<String> taxoVerTcoKeySet = new Set<String>();

        for (Taxonomy__c tx : taxList) {
            if (tx.RecordType.Name != BSF_Constants.BIO_COLLECTION_RECORD_TYPE) {
                continue;
            }
            if (String.isBlank(tx.Division_Code__c) ||
                String.isBlank(tx.DS_Region_Code__c) ||
                String.isBlank(tx.District_Code__c) ||
                String.isBlank(tx.Collection_Operation_Code__c)) {
                continue;
            }

            String tcoKey =
                'Bio_Collection_BSF_District_' +
                tx.Division_Code__c + '_' +
                tx.DS_Region_Code__c + '_' +
                tx.District_Code__c + '_' +
                tx.Collection_Operation_Code__c;

            // keep latest taxonomy for same key
            /*if (!keyToTaxMap.containsKey(tcoKey) || tx.End_Date__c > keyToTaxMap.get(tcoKey).End_Date__c) {
                keyToTaxMap.put(tcoKey, tx);
            }*/
            taxoVerTcoKeySet.add(tcoKey);
        }
        return taxoVerTcoKeySet;
    }

    /**
     * HRP-15653
     * End-date TCOs using SAME hierarchy logic as Territory
     * Hierarchy = Division + Region + District + Collection Operation
     */
    private static void endDateTCOsBatchSafe(
        Map<String, Taxonomy__c> oldKeyToTaxMap,
        Set<Id> terrIdSet,
        Set<String> allNewTaxoVerTcoKeySet) {

        if (terrIdSet.isEmpty()) {
            return;
        }
        List<sked_Territory_Collection_Operation__c> tcosToEndDateList  = new List<sked_Territory_Collection_Operation__c>();
        // STEP 1: Query ALL relevant TCOs (scope reduced by hierarchy later)
        List<sked_Territory_Collection_Operation__c> tcoList = [
            SELECT Id,
                sked_External_ID__c,
                sked_Start_Date__c,
                sked_End_Date__c,
                sked_Territory__r.External_Id_BackEnd__c,
                sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c
            FROM sked_Territory_Collection_Operation__c
            WHERE sked_Territory__c in :terrIdSet
            and sked_End_Date__c >=:System.today()
        ];
        if (tcoList.isEmpty()) {
            return;
        }
        // STEP 2: Compare hierarchy keys
        for (sked_Territory_Collection_Operation__c tco : tcoList) {

            if (String.isBlank(tco.sked_External_ID__c)) {
                continue;
            }
            //Format Bio_Collection_BSF_District_BD34_09E_3250 + _ + BSF_CO_0076
            String terrKey = tco.sked_Territory__r.External_Id_BackEnd__c;
            String comparableKey = terrKey +'_' + tco.sked_Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c ;
            // STEP 3: End-date if hierarchy no longer exists in new taxonomy
            if (!allNewTaxoVerTcoKeySet.contains(comparableKey)) {
                
                Date oldTaxEndDate =  (oldKeyToTaxMap != null) ? (oldKeyToTaxMap.containsKey(terrKey)) ? oldKeyToTaxMap.get(terrKey).End_Date__c : null : null;
                if(terrKey != null &&  oldTaxEndDate !=null){
                    if ( (tco.sked_Start_Date__c < oldKeyToTaxMap.get(terrKey).End_Date__c) && 
                        (tco.sked_End_Date__c != oldKeyToTaxMap.get(terrKey).End_Date__c) ) {
                    
                        tco.sked_End_Date__c = oldKeyToTaxMap.get(terrKey).End_Date__c;
                        tcosToEndDateList.add(tco);  
                    }
                }                 
            }
        }

        //Update the TCOs
        if(!tcosToEndDateList.isEmpty()){
            Map<Id, sked_Territory_Collection_Operation__c> uniqueTcos = new Map<Id, sked_Territory_Collection_Operation__c>();
            for (sked_Territory_Collection_Operation__c tco : tcosToEndDateList) {
                uniqueTcos.put(tco.Id, tco);
            }
            if (!uniqueTcos.isEmpty()) {
                Database.saveResult [] results = database.update(uniqueTcos.values(),false);
                //System.debug('HRP-15653 results:'+results);
                List<BSF_Error_Log__c> logList =
                    BSF_Utilities.createErrorLog(
                        results,
                        'Taxonomy EndDate',
                        'BSF_Batch_TaxonomyEndDateHelper',
                        'endDateTCOsForBioCollection',
                        'Error',
                        'Error while end-dating TCO records based on Taxonomy CO mapping'
                    );
                if (!logList.isEmpty()) {
                    InsertBsfErrorLog.insertBsfErrors(logList);
                }
            }
        }
    }
}