public class FormUtils {

    // Helper class for form validation.
    
    public static Boolean isValidPhone(string phone){
        
        if(String.isEmpty(phone)) return false;

        //String phoneRegex = '[0-9]{3}-[0-9]{3}-[0-9]{4}'; // Phone number must be formatted "999-999-9999"
        String phoneRegex = '[0-9]{3}-?[0-9]{3}-?[0-9]{4}'; // Phone number can be "999-999-9999" OR "9991118888"
        Pattern MyPattern = Pattern.compile(phoneRegex);

        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(phone);

        if (!MyMatcher.matches()) {
            system.debug('not a valid phone: ' + phone);
            return false;
        } else {
            system.debug('valid phone: ' + phone);
            return true;
        }
        
    }
    
    
    
    
    public static Boolean isValidEmail(string email){

        if(String.isEmpty(email)) return false;

        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,6}|[0-9]{1,3})';
        Pattern MyPattern = Pattern.compile(emailRegex);

        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) {
            system.debug('not a valid email: ' + email);
            return false;
        } else {
            system.debug('valid email: ' + email);
            return true;
        }

    }

    
    
    
    public static String cleanPhone(String tmpPhone){
        
        // Remove any dashes/spaces from the phone number. When a number without formatting is saved, Salesforce
        // will automatically apply consistent formatting like "(999) 222-4444" to the number.
        String cleanedNumber;
        
        cleanedNumber = tmpPhone.replace(' ', ''); // remove blank spaces
        cleanedNumber = cleanedNumber.replace('-',''); // remove dashes
        
        return cleanedNumber;
    }

    
}