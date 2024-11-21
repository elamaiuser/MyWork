public class StaticTest 
{
		public static Boolean doNotRunTrigger = false;

    public static void setDoNotRunTrigger(){
        doNotRunTrigger = true;
    }
    
    public static void setDoRunTrigger() {
        doNotRunTrigger = false;
    }

    public static Boolean shouldRunTrigger() {
        return !doNotRunTrigger;
    }
}