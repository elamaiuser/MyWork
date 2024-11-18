public class skedPrimaryRegionExcDataFixBatch implements Database.Batchable<SObject> {
     Map<String, sked__Region__c> regionsById;
    String regionIdPrefix;

    public skedPrimaryRegionExcDataFixBatch() {
        this.regionsById = new Map<String, sked__Region__c>([
            SELECT Id, Name
            FROM sked__Region__c
        ]);
        System.debug(regionsById);

        SObject instance = (SObject) Type.forName('Schema.sked__Region__c').newInstance();
        this.regionIdPrefix = instance.getSObjectType().getDescribe().getKeyPrefix();
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, skedHC__Exception__c
            FROM skedHC__Exception__c
            WHERE skedHC__Exception__c LIKE '%Primary Region changed%'
        ]);
    }

    public void execute(Database.BatchableContext BC, List<skedHC__Exception__c> exceptions) {
        for (skedHC__Exception__c skedExc : exceptions) {
            List<String> parts = skedExc.skedHC__Exception__c.split(' ');
            for (String part : parts) {
                if (part.startsWith(this.regionIdPrefix) && this.regionsById.containsKey(part)) {
                    skedExc.skedHC__Exception__c = skedExc.skedHC__Exception__c.replace(part, this.regionsById.get(part).Name);
                }
            }
        }
        update exceptions;
    }

    public void finish(Database.BatchableContext BC) {}
}