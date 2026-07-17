String code = skedConstants.EXCEPTION_CODE_ACTIVITY_OUTSIDE_OF_AVAILABILITY_PATTERN;

List<skedHC__Exception__c> toFix = [
    SELECT Id, skedHC__Activity__c, skedHC__Resource__c, sked_Exception_Code__c
    FROM skedHC__Exception__c
    WHERE sked_Exception_Code__c = :code
    AND (sked_UniqueKey__c = null OR sked_UniqueKey__c = '')
    AND skedHC__Activity__c != null
    AND skedHC__Resource__c != null
    AND skedHC__Status__c = 'Open'
    LIMIT 1000
];

System.debug('OUTSIDE_AP exceptions to backfill: ' + toFix.size());
for (skedHC__Exception__c ex : toFix) {
    ex.sked_UniqueKey__c = ex.skedHC__Activity__c + ':' + ex.skedHC__Resource__c + ':' + ex.sked_Exception_Code__c;
    System.debug('  ' + ex.Id + ' -> ' + ex.sked_UniqueKey__c);
}

if (!toFix.isEmpty()) {
    update toFix;
    System.debug('Backfilled ' + toFix.size() + ' record(s).');
}