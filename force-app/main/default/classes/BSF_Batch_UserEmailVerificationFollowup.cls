global class BSF_Batch_UserEmailVerificationFollowup implements Database.Batchable<SObject> {
	
    global Database.QueryLocator Start (Database.BatchableContext bc) {
        String query='SELECT Id, UserId, User.Name, ExternalId, HasUserVerifiedEmailAddress FROM  ' +
            'TwoFactorMethodsInfo WHERE HasUserVerifiedEmailAddress = false AND User.IsActive = true';
        
        return Database.getqueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<TwoFactorMethodsInfo> unverifiedUsers){
        for (TwoFactorMethodsInfo users : unverifiedUsers) {
            System.UserManagement.sendAsyncEmailConfirmation(users.UserId, null, null, null);
        }
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}