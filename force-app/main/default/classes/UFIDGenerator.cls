public with sharing class UFIDGenerator {
    @TestVisible
    static final String MASK = '0123456789ACDEFGHJKLMNPQRTUVWXY';
    
    @InvocableMethod
    public static List<String> genUFID(List<UFIDInfo> ufidInfos) {
        List<SObject> objectsToUpdate = new List<SObject>();
        String ufid;
        List<String> retVal = new List<String>();
        
        for (UFIDInfo theInfo : ufidInfos) {
            ufid = getUFID(theInfo.prefix, theInfo.maxLength, theInfo.value);
            Schema.sObjectType objType = theInfo.recordId.getSObjectType();
            SObject theObject = objType.newSObject(theInfo.recordId);
            theObject.put(theInfo.fieldName, ufid);
            retVal.add(ufid);
            objectsToUpdate.add(theObject);
        }
        try {
            update objectsToUpdate;
        } catch (DMLException ex) {
            System.debug('An error occured setting the UFID on record with Id: ' + ex.getDMLMessage(0));
        }
        
        return retVal;
    }
    
    static String getUFID(String prefix, Integer maxLength, Integer value) {
        String retVal = prefix;
        Integer remainder = value;
        List<Integer> offsets = new List<Integer>();
        
        while (remainder >= MASK.length()) {
            offsets.add(Math.mod(remainder, MASK.length()));
            remainder = remainder / MASK.length();
        }
        
        offsets.add(remainder);
        
        for ( Integer i = 1; i < maxLength - offsets.size(); i++ ) {
            retVal += '0';
        }
        
        for ( Integer i = offsets.size() - 1 ; i >= 0; i-- ) {
            retVal += MASK.subString(offsets[i], offsets[i]+1);
        }    
        
        return retVal;
    }
    
    public class UFIDInfo {
        @InvocableVariable( label='Record Prefix' description='A=Account, C=Contact, D=Drive' required=true)
        public String prefix;
        @InvocableVariable( label='UFID Max Length' description='Example 6 -> A000013' required=true )
        public Integer maxLength;
        @InvocableVariable( label ='Value to convert' description='Integer value to be converted to a UFID' required=true )
        public Integer value;   
        @InvocableVariable( label='Record Id' description='The Id of the record to update' required=true )
        public Id recordId;  
        @InvocableVariable( label='Field Name' description='The Name of the field in which to set the UFID' required=true )
        public String fieldName;                                           
    }
}