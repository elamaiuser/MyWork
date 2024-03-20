public class SObjectUtils {

    public static string getSObjectPrefix(sobjecttype type){
        String prefix = '';
        if(type != null){
            prefix = type.getDescribe().getKeyPrefix();
        }
        return prefix;
    }
}