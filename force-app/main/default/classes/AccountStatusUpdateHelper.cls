/* 
 * Modification Log 
 * Date               Developer Name           Comments
 * **********************************************************************************************************************************************************************************
 * 8/20/2025                 Barnojit Sharma           Logic for HRP-14999 (Account Status not updating to Inactive) 
 * 1/16/2026				 Souvik Mukherjee		   Fix for HRP-16472. Include check to ensure there are no future drives when determining account status based on latestCompletedDrive
 ************************************************************************************************************************************************************************************
*/
public inherited sharing class AccountStatusUpdateHelper {

    /**
     * Updates Account Statuses based on Opportunities, Drive dates, and CreatedDate.
     *
     * Business Rules:
     * ------------------------------------------------------------------
     * 1. Active:
     *    - Has a future non-cancelled Opportunity (Drive).
     *    - OR last completed drive < 12 months ago.
     *
     * 2. Reactivate:
     *    - Has a Discovery-stage Opportunity scheduled for today,
     *      and Account is Lost/Defunct.
     *
     * 3. Inactive:
     *    - No future drives AND last completed drive is 13–24 months ago.
     *    - OR no Opportunities at all, and Account age is 1–2 years.
     *
     * 4. Lapsed:
     *    - No future drives AND last completed drive is 24+ months ago.
     *
     * ------------------------------------------------------------------
     */
    public static void updateAcc(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()){
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();
        Date today = System.today();

        // Pull Accounts with Opportunities
        List<Account> accWithOpps = [
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
        ];
		
		
        for (Account acc : accWithOpps) {
			
            if (acc.Opportunities.isEmpty()) {
				
                Integer monthsOld = acc.CreatedDate.date().monthsBetween(today);

                if (monthsOld <= 12 && acc.Account_Status__c != 'Active') {
                    acc.Account_Status__c = 'Active';
                    accountsToUpdate.add(acc);					
                }else if (monthsOld >= 13 && monthsOld <= 24 && acc.Account_Status__c != 'Inactive') {
                    acc.Account_Status__c = 'Inactive';
                    accountsToUpdate.add(acc);
                }else if (monthsOld > 24 && acc.Account_Status__c != 'Lapsed') {
                    acc.Account_Status__c = 'Lapsed';
                    accountsToUpdate.add(acc);
                }
                continue;
            }

            Opportunity latestCompletedDrive;
            Opportunity futureDrive;

            for (Opportunity opp : acc.Opportunities) {
                if (opp.Drive_Date__c == null){
                    continue;
                }

                if (opp.Drive_Date__c >= today && opp.DriveStatus__c != BSF_Constants.driveStatusComplete) {
                    futureDrive = opp;
                }

                if (opp.DriveStatus__c == BSF_Constants.driveStatusComplete &&
                    (latestCompletedDrive == null || opp.Drive_Date__c > latestCompletedDrive.Drive_Date__c)) {
                    latestCompletedDrive = opp;
                }
            }
			

            if (futureDrive != null && acc.Account_Status__c != 'Active') {
                acc.Account_Status__c = 'Active';
                accountsToUpdate.add(acc);
            }else if (futureDrive != null && 
                futureDrive.Drive_Date__c >= today &&
                futureDrive.StageName == BSF_Constants.STAGE_DISCOVERY &&
                (acc.Account_Status__c == 'Lost' || acc.Account_Status__c == 'Defunct')) {
                acc.Account_Status__c = 'Reactivate';
                accountsToUpdate.add(acc);
            }else if (futureDrive == null && latestCompletedDrive != null) {		//HRP-16472
                Integer monthsSinceLastDrive = latestCompletedDrive.Drive_Date__c.monthsBetween(today);

                if (monthsSinceLastDrive <= 12) {
                    if (acc.Account_Status__c != 'Active') {
                        acc.Account_Status__c = 'Active';
                        accountsToUpdate.add(acc);
                    }
                }
                else if (monthsSinceLastDrive >= 13 && monthsSinceLastDrive <= 24) {
                    if (acc.Account_Status__c != 'Inactive') {
                        acc.Account_Status__c = 'Inactive';
                        accountsToUpdate.add(acc);
                    }
                }
                else if (monthsSinceLastDrive > 24) {
                    if (acc.Account_Status__c != 'Lapsed') {
                        acc.Account_Status__c = 'Lapsed';
                        accountsToUpdate.add(acc);
                    }
                }
            }
        }
		
        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update (accountsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Status to Inactive','AccountStatusUpdateHelper','updateAcc','Error','Error in updating Account Status to Inactive');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
}