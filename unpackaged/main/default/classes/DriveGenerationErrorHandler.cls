/* @CreatedBy - Priti Jana
 * @CreatedDate - 10/4/2023

 * @Description - 
 * ***************
 * The following apex class is used for drive generation related error handling
 * It will basically perform the following two operations
 * 			1. Send mail to BSF Support and Respective Users to notify them about drive generation failure
 * 			2. Log any type of errors (techinical/data issue)
 * 			3. Order of operation - 1. Create entry for BSF Error Log, 2. Send mail
 * It will be called from respective drive generation related apex classes
 * ******************************************************************************************************************************************
*/

public class DriveGenerationErrorHandler
{    
	// Creating error logs for technical/code issues as well as missing data issue   
    public static Id createBsfErrorLogs(Exception errors , String customMessage, String targetId, string issueType, String apexClass, String methodName)
    {        
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Type_Of_Drive__c, Source__c FROM Opportunity WHERE Id =:targetId]);
        BSF_Error_Log__c errorLog = new BSF_Error_Log__c();
        errorLog.ApexClass__c = apexClass ;
        errorLog.Object_Name__c = 'Opportunity';
        errorLog.Process_Name__c = Constants.CATEGORY ;
        errorLog.Method__c = methodName ;
        errorLog.Type__c = Constants.ERROR_LOG_TYPE ;
        errorLog.Functionality__c = getFunctionalityFromOppSourceAndType(oppMap,targetId);
        errorLog.Object_RecordId__c = targetId;
        if(issueType == Constants.TECHNICAL_ISSSUE)
        {
            if(errors!= NULL)
        	{ 
                errorLog.Error_Description__c = errors.getMessage().Length() > 255 ? errors.getMessage().subString(0,255) : errors.getMessage();
                errorLog.Error_Description_Long__c = errors.getStackTraceString().Length() > 2500 ? errors.getStackTraceString().subString(0,2500) : errors.getStackTraceString();                                        	 	
        	}
        }
        else
        {
            errorLog.Error_Description__c = Constants.ERROR_DESC_DATA_ISSUE;
            errorLog.Error_Description_Long__c = errorDescriptionForMissingDataIssue(customMessage);               
        }
        insert errorLog;    
        return errorLog!=NULL ? errorLog.Id : NULL;                             
     }
    
    // 1. Call this method from CreateSkedDrivesBatch Class
    public static void notifyUsersUponFailureAndLogErrors(Exception errors, String targetId, String customMessage,String issueType, String apexClass, String methodName)
    {
        system.debug('Inside notifyUsersUponFailureAndLogErrors method');
        try{
            
            if(issueType.containsIgnoreCase(Constants.DATA_ISSSUE))
            {
               Id errorLogId = createBsfErrorLogs(NULL, customMessage,targetId,issueType, apexClass, methodName);
               sendEmailNotification(customMessage,targetId, errorLogId); // for Data Issue 
           
            }else{
                Id errorLogId = createBsfErrorLogs(errors, customMessage,targetId,issueType, apexClass, methodName);
                sendEmailNotification(NULL,targetId, errorLogId); // for all sort of exception - No CustomMsg
            }
            
        }Catch(Exception ex)
        {            
            createBsfErrorLogs(ex,NULL,targetId,Constants.TECHNICAL_ISSSUE,'DriveGenerationErrorHandler','notifyUsersUponFailureAndLogErrors');        
        }
           
       }
    
    // method to form the custom email template 
    @testVisible
    private static void sendEmailNotification(String customMsg, String targetId, String errorLogId)
    {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    
        List<Email_Recipient__mdt> driveEmailList = [Select Id,Email__c,Active__c from Email_Recipient__mdt where Active__c = True AND Category__c =:Constants.CATEGORY];
        List<String> emailAddressList = new List<String>{UserInfo.getUserEmail()};
            
        if(!driveEmailList.isEmpty() && driveEmailList != null)
        {
            for(Email_Recipient__mdt recipientEmails : driveEmailList)
            {
                if(!emailAddressList.contains(recipientEmails.Email__c))
                {
                    emailAddressList.add(recipientEmails.Email__c);                    
                }                
            }
        }
        
        message.toAddresses = emailAddressList;
        message.optOutPolicy = 'FILTER';
        message.subject = Constants.EMAIL_SUBJECT;

        if(!String.isBlank(customMsg))
        {
            message.plainTextBody =  getEmailBody(customMsg,errorLogId,targetId);          
        }else{
            message.plainTextBody = getEmailBody(NULL,errorLogId,targetId);
        }
        
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);                   
    }
    
    // customized error description long to capture data issue
    @testVisible
    private static String errorDescriptionForMissingDataIssue(String customMsg)
    {
        String errorDesc;
        String errorDescription = customMsg.contains('\n') ? customMsg.replaceAll('\n', ', ') : customMsg ;
        errorDesc = errorDescription.Substring(0,errorDescription.length() -2);
        return errorDesc.length() > 2500 ? errorDesc.subString(0,2500) : errorDesc;                                                            
    }
    
    @testVisible
    private static String getEmailBody(String customMsg, String errorLogId, String oppId)
    {
        String emailBody = '';
        if(String.isBlank(customMsg)) // customMsg will be blank for technical issues
        {
            emailBody = 'Technical issue occured while generating drive for the below opportunity: \n'
                		+URL.getSalesforceBaseUrl().toExternalForm()+'/'+oppId+'\n'
                		+'For more details, please navigate to the BSF Error log : \n'
                		+URL.getSalesforceBaseUrl().toExternalForm()+'/'+errorLogId;
        }
        else{
            emailBody = 'Following data was not found while generating drive: \n'+customMsg+'\n'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+oppId;
        }
        
        return emailBody;
    }

    @testVisible
    private static String getFunctionalityFromOppSourceAndType(Map<Id,Opportunity> oppMap, String targetId)
    {
        String functionality = '';
        if(!String.isBlank(targetId))
        {
            String source = oppMap.get(targetId).Source__c == NULL ? '' : String.valueOf(oppMap.get(targetId).Source__c);
            String typeOfDrive = String.valueOf(oppMap.get(targetId).Type_of_Drive__c);
            if(source == Constants.SOURCE_CALENDAR_BUILD)
            {
                functionality = typeOfDrive == Constants.FIX_SITE_OPP ? Constants.CALENDAR_BUILD_FIXED_SITE_DRIVE : Constants.CALENDAR_BUILD_MOBILE_DRIVE;
            }
            else{
                functionality = typeOfDrive == Constants.FIX_SITE_OPP ? Constants.FIXED_SITE_DRIVE_GEN : Constants.MOBILE_DRIVE_GEN;
            }
        }
        return functionality;
    }

}