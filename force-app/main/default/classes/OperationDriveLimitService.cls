public with sharing class OperationDriveLimitService {

    public static void validate(List<sked_Operation_Drive_Limit__c> newItems) {
        List<sked_Operation_Drive_Limit__c> odlsWithTimeBlock = new List<sked_Operation_Drive_Limit__c>();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Operation_Drive_Limit__c odl : newItems) {
            if(odl.Time_Block__c!=null) {
                odlsWithTimeBlock.add(odl);
            collectionOperationIds.add(odl.sked_Collection_Operation__c);
        }
        }
        
        if (odlsWithTimeBlock.isEmpty()) return;

        List<Collection_Operation_Time_Block__c> coTimeBlockList = [
            SELECT Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c 
            FROM Collection_Operation_Time_Block__c  
            WHERE Collection_Operation__c IN :collectionOperationIds
        ];

        Map<Id, List<Collection_Operation_Time_Block__c>> coToCoTimeBlockMap = new Map<Id, List<Collection_Operation_Time_Block__c>>();
        for (Collection_Operation_Time_Block__c coTb : coTimeBlockList) {
            if (!coToCoTimeBlockMap.containsKey(coTb.Collection_Operation__c)) {
                coToCoTimeBlockMap.put(coTb.Collection_Operation__c, new List<Collection_Operation_Time_Block__c>());
            }
            coToCoTimeBlockMap.get(coTb.Collection_Operation__c).add(coTb);
        }

        for (sked_Operation_Drive_Limit__c odl : odlsWithTimeBlock) { 
            Boolean timeBlockMatched = false;
            Boolean dateRangeValid = false;
            List<Collection_Operation_Time_Block__c> relatedCOTimeBlocks = coToCoTimeBlockMap.get(odl.sked_Collection_Operation__c);
            if (relatedCOTimeBlocks != null) {
                for (Collection_Operation_Time_Block__c coTimeBlock : relatedCOTimeBlocks) {
                    if (coTimeBlock.Time_Block__c == odl.Time_Block__c) {
                        timeBlockMatched = true;
                        Boolean isValidStartDate = coTimeBlock.Effective_Start_Date__c <= odl.sked_Effective_Start_Date__c;
                        Boolean isValidEndDate = ((coTimeBlock.Effective_End_Date__c == null) || coTimeBlock.Effective_End_Date__c >= odl.sked_Effective_End_Date__c );
                        if (isValidStartDate && isValidEndDate) {
                            dateRangeValid = true;
                            break;
                        }
                    }
                }
            }
            if (!timeBlockMatched) {
                odl.addError(Label.ODL_TimeBlockNotAssociatedWithCO);
            } else if (!dateRangeValid) {
                odl.addError(Label.ODL_DateRangeOutsideTimeBlock);
            }
        }
    }
}