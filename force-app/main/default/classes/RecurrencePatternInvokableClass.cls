public class RecurrencePatternInvokableClass {

     @InvocableMethod(label='Get Selected Opportunity Ids as a List')
	public static List<List<String>> getOpportunityIds( List<List<String>> concatenatedIds) {  
        List<String> listOfIds = new List<String>();
        List<List<String>> listOfIdsoutput = new List<List<String>>();
        // if( concatenatedIds!=null && !concatenatedIds.isEmpty() ){
        //     listOfIds = concatenatedIds[0].split(';'); 
        // }
        System.debug( 'concatenatedIds is ' + concatenatedIds );
        //String[] splitids;
        if( concatenatedIds!=null && !concatenatedIds.isEmpty() ){
            listOfIds = concatenatedIds[0][0].split(';'); 
        }
        // for( String str : splitids ){
        //     if( str != ''){
        //         listOfIds.add( str );
        //     }
        // }
        listOfIdsoutput.add( listOfIds );      
        return listOfIdsoutput ;  
    }
}