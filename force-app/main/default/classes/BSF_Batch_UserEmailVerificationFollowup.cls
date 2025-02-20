global class BSF_Batch_UserEmailVerificationFollowup implements Database.Batchable<SObject> {

	global String queryClause = 'HasUserVerifiedEmailAddress = false AND User.IsActive = true';
	
    global BSF_Batch_UserEmailVerificationFollowup(){}
        
    global BSF_Batch_UserEmailVerificationFollowup(List<String> userIds) {
        if (userIds!=null && !userIds.isEmpty()) {
            String idString = '';
            for (String userId : userIds) {
                idString += '\'' + userId + '\','; 
            }
            idString = idString.removeEnd(','); 
            
            this.queryClause = 'UserId IN (' + idString + ')';
        }
    }

    global Database.QueryLocator Start (Database.BatchableContext bc) {
        String query='SELECT Id, UserId, User.Name, ExternalId, HasUserVerifiedEmailAddress FROM  ' +
            'TwoFactorMethodsInfo WHERE '+this.queryClause;
        System.debug('query: '+query);
        return Database.getqueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<TwoFactorMethodsInfo> unverifiedUsers){
        System.debug('unverifiedUsers: '+unverifiedUsers.size());
        for (TwoFactorMethodsInfo users : unverifiedUsers) {
            System.UserManagement.sendAsyncEmailConfirmation(users.UserId, null, null, null);
        }
    }
    
    global void finish(Database.BatchableContext bc){}
}