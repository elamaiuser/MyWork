/**
 * Authoritative gate for sked_Collection_Operation_Slot_Config__c (HRP-17440): guarantees no invalid row lands
 * regardless of entry point (LWC, Data Loader, API, Setup import), and fans out Drive Change Requests once a row lands.
 */
public class skedSlotConfigHandler extends skedTriggerHub {

    private static final Integer MINUTES_PER_HOUR = 60;
    private static final String KEY_SEPARATOR = '|';

    private static final Set<String> WHOLE_BLOOD_KEYS = new Set<String>{ 'slotDuration' };
    private static final Set<String> POWER_RED_KEYS = new Set<String>{ 'roundInterval', 'numberOfGroups', 'groupInterval', 'slotDuration' };

    private static final String ERROR_START_AFTER_END = 'Effective Start Date must be on or before Effective End Date.';
    private static final String ERROR_START_IMMUTABLE = 'Effective Start Date cannot be changed once the configuration has taken effect.';
    private static final String ERROR_FIXED_SITE_NEEDS_OPERATION_TYPE = 'Fixed Site Operation Type is required for a Fixed Site configuration.';
    private static final String ERROR_MOBILE_HAS_OPERATION_TYPE = 'Fixed Site Operation Type must be blank for a Mobile configuration.';

    public override void onBeforeInsert() {
        validateRecords();
    }

    public override void onBeforeUpdate() {
        validateRecords();
    }

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            createDriveChangeRequests((List<sked_Collection_Operation_Slot_Config__c>) this.context.newRecords);
        }
    }

    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            createDriveChangeRequests(getRecordsAffectingDrives());
        }
    }

    /*********************************************************** Private methods ***********************************************************/
    private void createDriveChangeRequests(List<sked_Collection_Operation_Slot_Config__c> slotConfigs) {
        if (!Test.isRunningTest() && !System.isBatch() && !slotConfigs.isEmpty()) {
            Database.executeBatch(new skedCreateDCRForSlotConfigChangeBatch(slotConfigs), 200);
        }
    }

    private List<sked_Collection_Operation_Slot_Config__c> getRecordsAffectingDrives() {
        List<String> fieldsToCheck = new List<String>{
            'sked_Collection_Operation__c', 'sked_Drive_Type__c', 'sked_Fixed_Site_Operation_Type__c',
            'sked_Procedure_Type__c', 'sked_Slot_Configuration__c', 'sked_Effective_Start_Date__c', 'sked_Effective_End_Date__c'
        };

        Map<Id, sked_Collection_Operation_Slot_Config__c> oldMap = (Map<Id, sked_Collection_Operation_Slot_Config__c>) this.context.oldMap;
        List<sked_Collection_Operation_Slot_Config__c> changedConfigs = new List<sked_Collection_Operation_Slot_Config__c>();

        for (sked_Collection_Operation_Slot_Config__c slotConfig : (List<sked_Collection_Operation_Slot_Config__c>) this.context.newRecords) {
            sked_Collection_Operation_Slot_Config__c oldSlotConfig = oldMap.get(slotConfig.Id);
            for (String fieldToCheck : fieldsToCheck) {
                if (slotConfig.get(fieldToCheck) != oldSlotConfig.get(fieldToCheck)) {
                    changedConfigs.add(slotConfig);
                    break;
                }
            }
        }

        return changedConfigs;
    }

    private void validateRecords() {
        if (skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE == true && !Test.isRunningTest()) {
            return;
        }

        Map<Id, sked_Collection_Operation_Slot_Config__c> oldMap = (Map<Id, sked_Collection_Operation_Slot_Config__c>) this.context.oldMap;

        Map<String, List<sked_Collection_Operation_Slot_Config__c>> pendingRowsByKey = new Map<String, List<sked_Collection_Operation_Slot_Config__c>>();
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> rowIdsInTransaction = new Set<Id>();

        for (sked_Collection_Operation_Slot_Config__c slotConfig : (List<sked_Collection_Operation_Slot_Config__c>) this.context.newRecords) {
            slotConfig.sked_Effective_End_Date__c = skedDateTimeUtils.getValueOrMaxDate(slotConfig.sked_Effective_End_Date__c);

            String shapeError = validateSlotConfiguration(slotConfig.sked_Procedure_Type__c, slotConfig.sked_Slot_Configuration__c);
            if (shapeError != NULL) {
                slotConfig.addError(shapeError);
                continue;
            }

            String pairingError = validateDriveTypePairing(slotConfig);
            if (pairingError != NULL) {
                slotConfig.addError(pairingError);
                continue;
            }

            if (slotConfig.sked_Effective_Start_Date__c > slotConfig.sked_Effective_End_Date__c) {
                slotConfig.addError(ERROR_START_AFTER_END);
                continue;
            }

            sked_Collection_Operation_Slot_Config__c oldSlotConfig = oldMap == NULL ? NULL : oldMap.get(slotConfig.Id);
            Boolean isStartDateLocked = oldSlotConfig != NULL && oldSlotConfig.sked_Effective_Start_Date__c <= Date.today();
            if (isStartDateLocked && oldSlotConfig.sked_Effective_Start_Date__c != slotConfig.sked_Effective_Start_Date__c) {
                slotConfig.addError(ERROR_START_IMMUTABLE);
                continue;
            }

            String key = buildRowKey(slotConfig);
            if (!pendingRowsByKey.containsKey(key)) {
                pendingRowsByKey.put(key, new List<sked_Collection_Operation_Slot_Config__c>());
            }
            pendingRowsByKey.get(key).add(slotConfig);

            collectionOperationIds.add(slotConfig.sked_Collection_Operation__c);
            if (slotConfig.Id != NULL) {
                rowIdsInTransaction.add(slotConfig.Id);
            }
        }

        if (!pendingRowsByKey.isEmpty()) {
            validateNoOverlap(pendingRowsByKey, collectionOperationIds, rowIdsInTransaction);
        }
    }

    /**
     * @return null when the payload is valid for its procedure, otherwise a user-facing reason.
     */
    private String validateSlotConfiguration(String procedureType, String slotConfigurationJson) {
        if (String.isBlank(slotConfigurationJson)) {
            return 'Slot Configuration is required.';
        }

        Set<String> expectedKeys = expectedKeysFor(procedureType);
        if (expectedKeys == NULL) {
            return 'Unsupported Procedure Type: ' + procedureType + '.';
        }

        Map<String, Object> payload;
        try {
            payload = (Map<String, Object>) JSON.deserializeUntyped(slotConfigurationJson);
        }
        catch (Exception ex) {
            return 'Slot Configuration is not valid JSON.';
        }

        for (String key : payload.keySet()) {
            if (!expectedKeys.contains(key)) {
                return 'Slot Configuration contains an unexpected field for ' + procedureType + ': ' + key + '.';
            }
        }

        for (String key : expectedKeys) {
            if (!payload.containsKey(key)) {
                return 'Slot Configuration is missing a required field for ' + procedureType + ': ' + key + '.';
            }
            if (!isPositiveWholeNumber(payload.get(key))) {
                return 'Slot Configuration field ' + key + ' must be a positive whole number of minutes.';
            }
        }

        if (skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_WHOLE_BLOOD.equals(procedureType)) {
            Integer slotDuration = Integer.valueOf(payload.get('slotDuration'));
            if (Math.mod(MINUTES_PER_HOUR, slotDuration) != 0) {
                return 'Whole Blood Slot Duration must divide 60 evenly so every hour holds a whole number of rounds.';
            }
        }

        return NULL;
    }

    private Set<String> expectedKeysFor(String procedureType) {
        if (skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_WHOLE_BLOOD.equals(procedureType)) {
            return WHOLE_BLOOD_KEYS;
        }
        if (skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_POWER_RED.equals(procedureType)) {
            return POWER_RED_KEYS;
        }
        return NULL;
    }

    private Boolean isPositiveWholeNumber(Object value) {
        if (!(value instanceof Integer) && !(value instanceof Decimal) && !(value instanceof Double)) {
            return false;
        }
        Decimal numericValue = Decimal.valueOf(String.valueOf(value));
        return numericValue > 0 && numericValue.scale() == 0;
    }

    /**
     * Mobile rows never carry a Fixed Site Operation Type, so it is excluded from the key for them rather than
     * concatenated raw - otherwise two Mobile rows would not group together.
     */
    private String buildRowKey(sked_Collection_Operation_Slot_Config__c row) {
        Boolean isFixedSite = skedConstants.DRIVE_TYPE_FIXED_SITE.equals(row.sked_Drive_Type__c);
        return String.join(
            new List<String>{
                row.sked_Collection_Operation__c == NULL ? '' : String.valueOf(row.sked_Collection_Operation__c),
                blankIfNull(row.sked_Drive_Type__c),
                isFixedSite ? blankIfNull(row.sked_Fixed_Site_Operation_Type__c) : '',
                blankIfNull(row.sked_Procedure_Type__c)
            },
            KEY_SEPARATOR
        );
    }

    private String blankIfNull(String value) {
        return String.isBlank(value) ? '' : value;
    }

    /**
     * Without a matching Drive Type / Fixed Site Operation Type pair there is no org-wide default to resolve against,
     * so an unpaired row would only fail later, at slot generation time.
     */
    private String validateDriveTypePairing(sked_Collection_Operation_Slot_Config__c slotConfig) {
        Boolean isFixedSite = skedConstants.DRIVE_TYPE_FIXED_SITE.equals(slotConfig.sked_Drive_Type__c);
        if (isFixedSite && String.isBlank(slotConfig.sked_Fixed_Site_Operation_Type__c)) {
            return ERROR_FIXED_SITE_NEEDS_OPERATION_TYPE;
        }
        if (!isFixedSite && String.isNotBlank(slotConfig.sked_Fixed_Site_Operation_Type__c)) {
            return ERROR_MOBILE_HAS_OPERATION_TYPE;
        }
        return NULL;
    }

    /**
     * Gaps between effective periods are allowed - they fall through to the org-wide default. Only overlap is ambiguous.
     */
    private void validateNoOverlap(
        Map<String, List<sked_Collection_Operation_Slot_Config__c>> pendingRowsByKey,
        Set<Id> collectionOperationIds,
        Set<Id> rowIdsInTransaction
    ) {
        Map<String, List<effectivePeriod>> periodsByKey = new Map<String, List<effectivePeriod>>();

        for (sked_Collection_Operation_Slot_Config__c persistedConfig : [
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Type__c, sked_Fixed_Site_Operation_Type__c,
                sked_Procedure_Type__c, sked_Effective_Start_Date__c, sked_Effective_End_Date__c
            FROM sked_Collection_Operation_Slot_Config__c
            WHERE sked_Collection_Operation__c IN :collectionOperationIds
            AND Id NOT IN :rowIdsInTransaction
        ]) {
            String key = buildRowKey(persistedConfig);
            if (pendingRowsByKey.containsKey(key)) {
                addPeriod(periodsByKey, key, new effectivePeriod(persistedConfig, false));
            }
        }

        for (String key : pendingRowsByKey.keySet()) {
            for (sked_Collection_Operation_Slot_Config__c pendingConfig : pendingRowsByKey.get(key)) {
                addPeriod(periodsByKey, key, new effectivePeriod(pendingConfig, true));
            }
        }

        for (String key : periodsByKey.keySet()) {
            List<effectivePeriod> periods = periodsByKey.get(key);
            periods.sort();

            for (Integer i = 0; i < periods.size() - 1; i++) {
                effectivePeriod earlier = periods[i];
                effectivePeriod later = periods[i + 1];
                if (earlier.endDate < later.startDate) {
                    continue;
                }

                effectivePeriod periodToFlag = later.isPending ? later : earlier;
                effectivePeriod conflictingPeriod = later.isPending ? earlier : later;
                periodToFlag.record.addError(buildOverlapError(conflictingPeriod));
            }
        }
    }

    private void addPeriod(Map<String, List<effectivePeriod>> periodsByKey, String key, effectivePeriod period) {
        if (!periodsByKey.containsKey(key)) {
            periodsByKey.put(key, new List<effectivePeriod>());
        }
        periodsByKey.get(key).add(period);
    }

    private String buildOverlapError(effectivePeriod conflictingPeriod) {
        String conflictingEndDate = conflictingPeriod.endDate == skedDateTimeUtils.MAX_DATE
            ? 'open-ended'
            : String.valueOf(conflictingPeriod.endDate);
        return 'This effective period overlaps an existing configuration for the same Collection Operation, Drive Type and Procedure Type ('
            + conflictingPeriod.startDate + ' to ' + conflictingEndDate + '). Close the existing period before adding a new one.';
    }

    /*********************************************************** Nested classes ***********************************************************/
    private class effectivePeriod implements Comparable {
        private final sked_Collection_Operation_Slot_Config__c record;
        private final Date startDate;
        private final Date endDate;
        private final Boolean isPending;

        private effectivePeriod(sked_Collection_Operation_Slot_Config__c record, Boolean isPending) {
            this.record = record;
            this.startDate = record.sked_Effective_Start_Date__c;
            this.endDate = skedDateTimeUtils.getValueOrMaxDate(record.sked_Effective_End_Date__c);
            this.isPending = isPending;
        }

        public Integer compareTo(Object other) {
            effectivePeriod otherPeriod = (effectivePeriod) other;
            if (this.startDate == otherPeriod.startDate) {
                return 0;
            }
            return this.startDate < otherPeriod.startDate ? -1 : 1;
        }
    }
}