global class BSF_BatchUpdateAccountForZipCode implements Database.Batchable<sObject> {
    
    private Boolean reevaluateZip;
    
    global BSF_BatchUpdateAccountForZipCode() {
        this.reevaluateZip = false;
    }
    
    global BSF_BatchUpdateAccountForZipCode(Boolean reevaluateZip) {
        this.reevaluateZip = reevaluateZip;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        
        if(reevaluateZip){
            query = 'SELECT Id, Zip__c, Name, sked_Start_Date__c, sked_End_Date__c ' +
                    'FROM Collections_Territory__c ' +
                    'WHERE sked_Start_Date__c <= TODAY AND sked_End_Date__c >= TODAY';
        }else{
            query = 'SELECT Id, Zip__c, Name, sked_Start_Date__c, sked_End_Date__c ' +
                    'FROM Collections_Territory__c ' +
                    'WHERE LastModifiedDate >= YESTERDAY AND LastModifiedDate <= TODAY';
        }
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Collections_Territory__c> listOfCollectionTerrritory) {
        Map<String, List<Collections_Territory__c>> mapOfCollectionTerritory = new Map<String, List<Collections_Territory__c>>();
        
        for (Collections_Territory__c czipCodeRecord : listOfCollectionTerrritory) {
            if (!mapOfCollectionTerritory.containsKey(czipCodeRecord.Zip__c)) {
                mapOfCollectionTerritory.put(czipCodeRecord.Zip__c, new List<Collections_Territory__c>());
            }
            mapOfCollectionTerritory.get(czipCodeRecord.Zip__c).add(czipCodeRecord);
        }
        
        List<Account> listOfAccountsToUpdate = new List<Account>();

        if(!mapOfCollectionTerritory.isEmpty()){
            List<Account> listOfAccounts = [SELECT Id, 
                                                    CreatedDate, 
                                                    Collections_Territory__c, 
                                                    BillingPostalCode
                                            FROM Account
                                            WHERE BillingPostalCode IN :mapOfCollectionTerritory.keySet()];
            
            for (Account accRecord : listOfAccounts) {
                if (mapOfCollectionTerritory.containsKey(accRecord.BillingPostalCode)) {
                    for (Collections_Territory__c ctr : mapOfCollectionTerritory.get(accRecord.BillingPostalCode)) {
                        if (System.today() >= ctr.sked_Start_Date__c 
                                && ctr.sked_End_Date__c >= System.today() 
                                && accRecord.Collections_Territory__c != ctr.Id) {
                                    accRecord.Collections_Territory__c = ctr.Id;
                                    listOfAccountsToUpdate.add(accRecord);
                                    break;
                        }
                    }
                }
            }
        }
        
        if (!listOfAccountsToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update (listOfAccountsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Collections Territory','BSF_BatchUpdateAccountForZipCode','updateAcc','Error','updating Account Collections Territory(ZIP Codes)');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    
    global void finish(Database.BatchableContext bc) {}
}
