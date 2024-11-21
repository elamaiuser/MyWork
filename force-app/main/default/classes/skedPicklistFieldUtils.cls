public class skedPicklistFieldUtils {
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
    
    public static Map<String, List<String>> getMapDependentOptions(Schema.SObjectField ctrlField, Schema.SObjectField depField) {
        List<Schema.PicklistEntry> ctrlEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(depField.getDescribe().getPicklistValues());
        
        Map<String, List<String>> result = new Map<String, List<String>>();
        
        for (Schema.PicklistEntry entry : ctrlEntries) {
            String value = entry.getValue();
            result.put(value, new List<String>());
        }
        
        for (PicklistEntryWrapper entry : depEntries) {
            String value = entry.value;
            String validForBits = base64ToBits(entry.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    result.get(ctrlEntries.get(i).getValue()).add(value);
                }
            }
        }
        
        return result;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> picklistEntries) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(picklistEntries), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper {
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
    }
    
}