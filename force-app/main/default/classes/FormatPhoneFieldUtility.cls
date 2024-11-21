public without sharing class FormatPhoneFieldUtility {

    public static void formatPhoneFields(List<String> fieldNames, List<SObject> sObjects){
        if(sObjects!=null && sObjects.size()>0 && fieldNames!=null && fieldNames.size()>0){
            for(SObject sobj : sObjects ){
                for(String fieldName : fieldNames ){
                    sobj.put(fieldName, removeSpecialCharacters((String)sobj.get(fieldName)));
                }
            }
        }
    }

    public static String removeSpecialCharacters(String phoneNumber){
        System.debug(' FormatPhoneFieldUtility.removeSpecialCharacters before phoneNumber: ' + phoneNumber);
        if(phoneNumber!=null){
            phoneNumber = phoneNumber.replaceAll('[^a-zA-Z0-9]', '');
            System.debug(' FormatPhoneFieldUtility.removeSpecialCharacters after phoneNumber: ' + phoneNumber);
        }

        return phoneNumber;
    }

    /*public static void createFormatPhoneFieldTrigger(String objectName, String triggerName){
        ApexTriggerREST.TriggerInfoWrapper obj = new ApexTriggerREST.TriggerInfoWrapper(objectName,triggerName,generateTriggerBody(objectName,triggerName));

        ApexTriggerREST.createApexTrigger(obj);
    }

    public static String generateTriggerBody(String objectName, String triggerName){
        String body = 'trigger '+triggerName+' on '+objectName+' (before insert, before update) {';
        body+='   List<String> phoneFields = FormatPhoneFieldUtility.getPhoneFields(\''+objectName+'\');' +
            '        List<SObject> sObjects = Trigger.new;' +
            '        for(SObject sobj : sObjects){' +
            '            for(String phoneField : phoneFields){' +
            '                sobj.put(phoneField,FormatPhoneFieldUtility.removeSpecialCharacters((String)sobj.get(phoneField)));' +
            '            }}}' ;
        System.debug(' FormatPhoneFieldUtility.generateTriggerBody body: ' + JSON.serialize(body));
        return body;
    }

    private static Map<String, Schema.SObjectType > globalDescription = Schema.getGlobalDescribe();


    public static List<String> getPhoneFields(String objectName){
        List<String> phoneFieldNames = new List<String>();
        Schema.sObjectType objType = globalDescription.get( objectName );
        Schema.DescribeSObjectResult r1 = objType.getDescribe();
        Map<String , Schema.SObjectField > mapFieldList = r1.fields.getMap();

        for ( Schema.SObjectField field : mapFieldList.values() ) {

            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            String fieldLabel = fieldResult.getLabel().toLowerCase();
            Schema.DisplayType fielddataType = fieldResult.getType();

            if ( fielddataType == Schema.DisplayType.Phone ) {
                phoneFieldNames.add(fieldResult.getName());
                System.debug( objType + '.' + fieldResult.getName() );

            }*//*  else if ( fieldLabel.contains( 'phone' ) && ! fieldResult.isCalculated() ) {

                System.debug ( objType + '.' + fieldResult.getName() );

            }*//*

        }
        return phoneFieldNames;
    }*/
}