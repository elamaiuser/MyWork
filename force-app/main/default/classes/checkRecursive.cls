public class checkRecursive {
     public static Boolean firstcall = false;
     public static Boolean isNewlyCreatedAccount = false;
     public static Boolean skipAptRecalculation = false;
     public static Boolean firstCallForRecordCreation = false;

     //HRP-13146: To skip volunteer recalculation during DOC -> OPP Sync , Apply changes to future drive updates
     public static Boolean skipVolunteerCalculation = false; 
}