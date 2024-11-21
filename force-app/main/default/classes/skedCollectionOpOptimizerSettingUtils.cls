public class skedCollectionOpOptimizerSettingUtils {
    private static Map<String, Decimal> defaultWeightMap = getDefaultWeight();

    public static void populateOptimizerMappedWeight(
        List<sked_CollectionOperationOptimizerSetting__c> optimizerSettings,
        Map<Id, Biomed_Collection_Op_Center__c> collectionOperationMap
    ) {
        for (sked_CollectionOperationOptimizerSetting__c optimizerSetting : optimizerSettings) {
            Biomed_Collection_Op_Center__c collectionOperation = collectionOperationMap.get(optimizerSetting.sked_Collection_Operation__c);
            if (collectionOperation != null) {
                populateOptimizerMappedWeight(optimizerSetting, collectionOperation);
            }
        }
    }

    public static void populateOptimizerMappedWeight(sked_CollectionOperationOptimizerSetting__c optimizerSetting, Biomed_Collection_Op_Center__c collectionOperation) {
        Decimal weightValue = getWeightValue(optimizerSetting, collectionOperation);
        String weightPostfix = getWeightPostfix(optimizerSetting.sked_Constraint_Type__c);

        optimizerSetting.sked_Optimizer_Mapped_Weight__c = weightValue.intValue() + weightPostfix;
    }

    private static Decimal getWeightValue(sked_CollectionOperationOptimizerSetting__c optimizerSetting, Biomed_Collection_Op_Center__c collectionOperation) {
        if (optimizerSetting.sked_Display_Type__c ==  skedConstants.OPTIMIZATION_SETTING_DISPLAY_TYPE_PICKLIST) {
            return getWeightValuePicklist(optimizerSetting.sked_Default_Weight__c, collectionOperation);
        } else if (optimizerSetting.sked_Display_Type__c ==  skedConstants.OPTIMIZATION_SETTING_DISPLAY_TYPE_CHECKBOX
            && optimizerSetting.sked_Enabled__c == true) {
            return getWeightValueCheckbox(optimizerSetting.sked_Constraint__c, collectionOperation);
        }

        return 0;
    }

    private static Decimal getWeightValuePicklist(String weightLevel, Biomed_Collection_Op_Center__c collectionOperation) {
        Decimal weight = null;
        if (skedConstants.OPTIMIZATION_WEIGHT_LEVEL_LOW.equalsIgnoreCase(weightLevel)) {
            weight = collectionOperation.sked_Low_Weight__c;
        } else if (skedConstants.OPTIMIZATION_WEIGHT_LEVEL_MEDIUM.equalsIgnoreCase(weightLevel)) {
            weight = collectionOperation.sked_Medium_Weight__c;
        } else if (skedConstants.OPTIMIZATION_WEIGHT_LEVEL_HIGH.equalsIgnoreCase(weightLevel)) {
            weight = collectionOperation.sked_High_Weight__c;
        } 
        
        return weight ?? defaultWeightMap.get(weightLevel) ?? 0;
    }

    private static Decimal getWeightValueCheckbox(String constraint, Biomed_Collection_Op_Center__c collectionOperation) {
        Decimal weight = null;
        if (skedConstants.OPTIMIZATION_WEIGHT_ROLE_PRIORITIES.equalsIgnoreCase(constraint)) {
            weight = collectionOperation.sked_Role_Priorities_Weight__c;
        }
        
        return weight ?? defaultWeightMap.get(constraint) ?? 0;
    }

    private static String getWeightPostfix(String constraintType) {
        if (skedConstants.OPTIMIZATION_CONSTRAINT_TYPE_HARD.equalsIgnoreCase(constraintType)) {
            return skedConstants.OPTIMIZATION_WEIGHT_POSTFIX_HARD;
        } else {
            return skedConstants.OPTIMIZATION_WEIGHT_POSTFIX_SOFT;
        }
    }

    private static Map<String, Decimal> getDefaultWeight() {
        Map<String, Decimal> defaultWeightMap = new Map<String, Decimal>();
        for (sked_Optimizer_Default_Weight__mdt defaultWeight : [
            SELECT sked_Level__c, sked_Default_Value__c
            FROM sked_Optimizer_Default_Weight__mdt
        ]) {
            defaultWeightMap.put(defaultWeight.sked_Level__c, defaultWeight.sked_Default_Value__c);
        }

        return defaultWeightMap;
    }
}