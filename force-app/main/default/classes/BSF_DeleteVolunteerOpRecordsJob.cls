/**
 * Daily job: deletes Op Record Staff rows created yesterday for Volunteer resources,
 * then emails the technical team distribution list (from Workday Direct Submission config)
 * with Name and Email of deleted staff.
 *
 * System.schedule('BSF_DeleteVolunteerOpRecords Job', '0 15 0 * * ?', new BSF_DeleteVolunteerOpRecordsJob());
 */
public class BSF_DeleteVolunteerOpRecordsJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private static final String JOB_NAME = 'BSF_DeleteVolunteerOpRecords Job';

    private String technicalTeamDistributionList;
    private String notificationFromEmail;
    private List<String> deletedLines = new List<String>();
    private List<String> deleteErrors = new List<String>();
    private Integer deletedCount = 0;

    public BSF_DeleteVolunteerOpRecordsJob() {
        BSF_Workday_Direct_Submission_Config__mdt config = BSF_WorkdayDirectSubmissionConfig.getConfig();
        if (config != null) {
            technicalTeamDistributionList = config.sked_Technical_Team_Distribution_List__c;
            notificationFromEmail = config.sked_Notification_From_Email__c;
        }
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BSF_DeleteVolunteerOpRecordsJob(), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   CreatedDate,
                   sked_Workday_Submission_Status__c,
                   sked_Resource__c,
                   sked_Resource__r.Name,
                   sked_Resource__r.sked__Category__c,
                   sked_Resource__r.sked__Email__c,
                   sked_Resource__r.sked_Employee_ID__c,
                   sked_Operation_Record__c,
                   sked_Operation_Record__r.Name
            FROM sked_Operation_Record_Staff__c
            WHERE CreatedDate = YESTERDAY
              AND sked_Resource__r.sked__Category__c = 'Volunteer'
            ORDER BY CreatedDate DESC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sked_Operation_Record_Staff__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        List<String> deletedVolunteerDetails = new List<String>();
        for (sked_Operation_Record_Staff__c staff : scope) {
            String resourceName = staff.sked_Resource__r != null ? staff.sked_Resource__r.Name : '';
            String resourceEmail = staff.sked_Resource__r != null ? staff.sked_Resource__r.sked__Email__c : '';
            String opName = staff.sked_Operation_Record__r != null ? staff.sked_Operation_Record__r.Name : '';
            deletedVolunteerDetails.add(
                'Staff: ' + staff.Name +
                ' | Resource: ' + resourceName +
                ' | Email: ' + (String.isNotBlank(resourceEmail) ? resourceEmail : '(none)') +
                ' | Op Record: ' + opName +
                ' | Staff Id: ' + staff.Id
            );
        }

        Database.DeleteResult[] results = Database.delete(scope, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                deletedCount++;
                deletedLines.add(deletedVolunteerDetails[i]);
            } else {
                String errs = '';
                for (Database.Error e : results[i].getErrors()) {
                    errs += e.getStatusCode() + ': ' + e.getMessage() + '; ';
                }
                deleteErrors.add(deletedVolunteerDetails[i] + ' | ERROR: ' + errs);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        sendNotificationEmail();
    }

    private void sendNotificationEmail() {
        try {
            if (deletedCount == 0 && deleteErrors.isEmpty()) {
                return;
            }

            List<String> toList = parseCommaSeparatedEmails(technicalTeamDistributionList);
            if (toList.isEmpty()) {
                return;
            }

            List<String> bodyParts = new List<String>();
            bodyParts.add('<p><b>' + JOB_NAME + '</b> completed.</p>');
            bodyParts.add('<p>Deleted volunteer Op Record Staff count: ' + deletedCount + '</p>');

            if (!deletedLines.isEmpty()) {
                bodyParts.add('<p><b>Deleted staff (Name / Email):</b></p><pre>');
                bodyParts.add(String.join(deletedLines, '\n'));
                bodyParts.add('</pre>');
            }

            if (!deleteErrors.isEmpty()) {
                bodyParts.add('<p><b>Delete failures:</b></p><pre>');
                bodyParts.add(String.join(deleteErrors, '\n'));
                bodyParts.add('</pre>');
            }

            skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
            emailItem.fromAddress = notificationFromEmail;
            emailItem.subject = JOB_NAME + ' – ' + deletedCount + ' deleted';
            emailItem.htmlBody = String.join(bodyParts, '');
            emailItem.toList = toList;

            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(new List<skedEmailService.emailModel>{ emailItem });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, JOB_NAME + ' email failed: ' + e.getMessage());
        }
    }

    private static List<String> parseCommaSeparatedEmails(String commaSeparated) {
        List<String> toList = new List<String>();
        if (String.isBlank(commaSeparated)) {
            return toList;
        }
        for (String e : commaSeparated.split(',')) {
            String t = e.trim();
            if (String.isNotBlank(t)) {
                toList.add(t);
            }
        }
        return toList;
    }
}
