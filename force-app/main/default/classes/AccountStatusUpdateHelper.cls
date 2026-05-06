/* 
 * Modification Log 
 * Date               Developer Name           Comments
 * **********************************************************************************************************************************************************************************
 * 8/20/2025                 Barnojit Sharma           Logic for HRP-14999 (Account Status not updating to Inactive) 
 * 1/16/2026				 Souvik Mukherjee		   Fix for HRP-16472. Include check to ensure there are no future drives when determining account status based on latestCompletedDrive
 * 4/16/2026                 Eric Keating & Elam Pandian    Fix for HRP-16871. Require 'Confirmed' status on future drives to activate Accounts. Unified Account Age fallback logic for Prospects. Resolved SOQL assignment exception via FOR loop chunking.
 ************************************************************************************************************************************************************************************
*/
public inherited sharing class AccountStatusUpdateHelper {

    /**
     * Updates Account Statuses based on Opportunities, Drive dates, and CreatedDate.
     *
     * Business Rules:
     * ------------------------------------------------------------------
     * 1. Active:
     *    - Has a future CONFIRMED Opportunity (Drive).
     *    - OR last completed drive was <= 12 months ago.
     *    - OR no Confirmed/Completed drives exist, but Account is <= 12 months old
     *      (Note: Brand new Accounts created as 'Prospect' will remain 'Prospect' 
     *       until they get a Confirmed/Completed drive).
     *
     * 2. Reactivate:
     *    - Has a Discovery-stage Opportunity scheduled for today,
     *      and Account is currently in 'Lost' or 'Defunct' status.
     *
     * 3. Inactive:
     *    - No future Confirmed drives AND last completed drive was 13–24 months ago.
     *    - OR no Confirmed/Completed drives exist, and Account age is 13–24 months.
     *
     * 4. Lapsed:
     *    - No future Confirmed drives AND last completed drive is > 24 months ago.
     *    - OR no Confirmed/Completed drives exist, and Account age is > 24 months.
     *
     * ------------------------------------------------------------------
     */
    public static void updateAcc(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()){
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();
        Date today = System.today();

        // HRP-16781 fix: Use a SOQL for loop to process Accounts one at a time to prevent the 200 record limit in memory and avoid Too many query rows: 50001 error.
        for (Account acc : [
            SELECT Id, 
                    Account_Status__c, 
                    CreatedDate,
                   (SELECT Id, 
                            Drive_Date__c, 
                            StageName, 
                            DriveStatus__c, 
                            Is_Template__c
                    FROM Opportunities
                    WHERE Is_Template__c = FALSE
                    AND StageName != :BSF_Constants.STAGE_CANCELLED
                    ORDER BY Drive_Date__c DESC)
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            Opportunity latestCompletedDrive;            
            Opportunity futureConfirmedDrive; // EK-HRP-16871
            Opportunity futureDiscoveryDrive; // HRP-16781 fix For Reactivation logic

            for (Opportunity opp : acc.Opportunities) {
                if (opp.Drive_Date__c == null){
                    continue;
                }
                // EK-HRP-16871 Check for future confirmed or discovery drives
                if (opp.Drive_Date__c >= today) {
                    if (opp.DriveStatus__c == BSF_Constants.driveStatusConfirmed) {
                        futureConfirmedDrive = opp;
                    }
                    if (opp.StageName == BSF_Constants.STAGE_DISCOVERY) {
                        futureDiscoveryDrive = opp;
                    }
                }

                // Check Completed drives
                if (opp.DriveStatus__c == BSF_Constants.driveStatusComplete &&
                    (latestCompletedDrive == null || opp.Drive_Date__c > latestCompletedDrive.Drive_Date__c)) {
                    latestCompletedDrive = opp;
                }
            }

            // Unified business logic for Active, Reactivate, Inactive, and Lapsed status updates

            // Rule 1: Active if there's a future confirmed drive
            if (futureConfirmedDrive != null && acc.Account_Status__c != 'Active') { // EK-HRP-16871 using futureConfirmedDrive instead of futureDrive
                acc.Account_Status__c = 'Active';
                accountsToUpdate.add(acc);
            }
            // Rule 2: Reactivate if there's a future discovery drive and account is Lost or Defunct
            else if (futureDiscoveryDrive != null &&
                (acc.Account_Status__c == 'Lost' || acc.Account_Status__c == 'Defunct')) {
                acc.Account_Status__c = 'Reactivate';
                accountsToUpdate.add(acc);
            }
            // Rule 3: Evaluate based on the latest completed drive (if one exists)
            else if (latestCompletedDrive != null) {		//HRP-16472 EK-HRP-16871 added futureConfirmedDrive condition
                Integer monthsSinceLastDrive = latestCompletedDrive.Drive_Date__c.monthsBetween(today);

                if (monthsSinceLastDrive <= 12 && acc.Account_Status__c != 'Active') {
                    acc.Account_Status__c = 'Active';
                    accountsToUpdate.add(acc);                    
                }else if (monthsSinceLastDrive >= 13 && monthsSinceLastDrive <= 24 && acc.Account_Status__c != 'Inactive') {
                    acc.Account_Status__c = 'Inactive';
                    accountsToUpdate.add(acc);                    
                }else if (monthsSinceLastDrive > 24 && acc.Account_Status__c != 'Lapsed') {
                    acc.Account_Status__c = 'Lapsed';
                    accountsToUpdate.add(acc);
                }
            }
            // RULE 4: No Confirmed or Completed drives exist. Evaluate based strictly on Account Age.
            // (This correctly keeps < 12mo accounts as Prospect, and ages out older ones to Inactive/Lapsed)
            else {
                Integer monthsOld = acc.CreatedDate.date().monthsBetween(today);

                if (monthsOld <= 12) {
                    // Do not touch Prospect status, but activate if it somehow ended up in a weird state
                    if (acc.Account_Status__c != 'Active' && acc.Account_Status__c != 'Prospect') {
                        acc.Account_Status__c = 'Active';
                        accountsToUpdate.add(acc);					
                    }
                } else if (monthsOld >= 13 && monthsOld <= 24 && acc.Account_Status__c != 'Inactive') {
                    acc.Account_Status__c = 'Inactive';
                    accountsToUpdate.add(acc);
                } else if (monthsOld > 24 && acc.Account_Status__c != 'Lapsed') {
                    acc.Account_Status__c = 'Lapsed';
                    accountsToUpdate.add(acc);
                }
            }
        }
		
        // Save updates
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update (accountsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Status to Inactive','AccountStatusUpdateHelper','updateAcc','Error','Error in updating Account Status to Inactive');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
}