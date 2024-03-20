public with sharing class skedOppDriveSyncBatch implements Database.Batchable<sked_Drive__c>, Database.Stateful {
    List<String> toAddresses;
    
    static Map<String, String> driveFieldLabelsByApiName = new Map<String, String>{
        'sked_Drive_Date__c' => 'Drive Date',
        'sked_Start_Time__c' => 'Start Time',
        'sked_End_Time__c' => 'End Time',
        'sked_Projected_Registered_Donors__c' => 'Projected Registered Donors',
        'sked_2RBC_Projected_Procedures__c' => '2RBC Projected Procedures',
        'sked_Plasma_Projected_Procedures__c' => 'Plasma Projected Procedures',
        'sked_Platelet_Projected_Procedures__c' => 'Platelet Projected Procedures',
        'sked_WB_Projected_Procedures__c' => 'WB Projected Procedures'
    };

    static Map<String, String> driveToOppLogisticFields = new Map<String, String>{
        'sked_Drive_Date__c' => 'Drive_Date__c',
        'sked_Start_Time__c' => 'Start_Time__c',
        'sked_End_Time__c' => 'End_Time__c',
        'sked_Projected_Registered_Donors__c' => 'Anticipated_Registered_Donors__c',
        'sked_2RBC_Projected_Procedures__c' => 'X2RBC_Projected_Procedures__c',
        'sked_Plasma_Projected_Procedures__c' => 'Plasma_Pheresis_Projected_Procedures__c',
        'sked_Platelet_Projected_Procedures__c' => 'Platelet_Projected_Procedures__c',
        'sked_WB_Projected_Procedures__c' => 'WB_Projected_Procedures__c'
    };

    public skedOppDriveSyncBatch(List<String> toAddresses) {
        this.toAddresses = toAddresses;
    }

    public List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, Name, sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, 
            sked_Projected_Registered_Donors__c, sked_2RBC_Projected_Procedures__c, 
            sked_Plasma_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, 
            sked_WB_Projected_Procedures__c, sked_Opportunity__r.Drive_Date__c, 
            sked_Opportunity__r.Start_Time__c, sked_Opportunity__r.End_Time__c, 
            sked_Opportunity__r.Anticipated_Registered_Donors__c, 
            sked_Opportunity__r.X2RBC_Projected_Procedures__c, 
            sked_Opportunity__r.Plasma_Pheresis_Projected_Procedures__c, 
            sked_Opportunity__r.Platelet_Projected_Procedures__c, 
            sked_Opportunity__r.WB_Projected_Procedures__c
            FROM sked_Drive__c
            WHERE sked_Is_Logistic_Different__c = TRUE
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        if (drives != null && !drives.isEmpty()) {
            List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
            for (sked_Drive__c drive : drives) {
                String recordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + drive.Id;
                String driveHyperlink = '<a href="' + recordUrl + '">' + drive.Name + '</a>';
                String htmlTable = '<table style="border: 3px solid;border-collapse: collapse;">';
                htmlTable += '<tr><th>Field Name</th>';
                htmlTable += '<th>DOC Value</th>';
                htmlTable += '<th>Opportunity Value</th></tr>';
                for (String fieldName : driveToOppLogisticFields.keySet()) {
                    String fieldLabel = driveFieldLabelsByApiName.get(fieldName);
                    String oppFieldName = driveToOppLogisticFields.get(fieldName);
                    Opportunity opp = (Opportunity) drive.sked_Opportunity__r;
                    if (drive.get(fieldName) != opp.get(oppFieldName)) {
                        htmlTable += '<tr><td>' + fieldLabel + '</td>';
                        htmlTable += '<td>' + String.valueOf(drive.get(fieldName)) + '</td>';
                        htmlTable += '<td>' + String.valueOf(opp.get(oppFieldName)) + '</td></tr>';
                    }
                }
                htmlTable += '</table>';
                htmlTable = htmlTable.replace('<tr>', '<tr style="border: 1px solid;">');
                htmlTable = htmlTable.replace('<th>', '<th style="border: 1px solid;">');
                htmlTable = htmlTable.replace('<td>', '<td style="border: 1px solid;">');

                String htmlBody = 'ALERT:  Opportunity and Drive Sync Error - [' + driveHyperlink +']';
                htmlBody += ' <br /><br /><br /> ';
                htmlBody += htmlTable;

                skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
                emailItem.subject = 'ALERT:  Opportunity and Drive Sync Error - [' + drive.name +']';
                emailItem.htmlBody = htmlBody;
                emailItem.toList = this.toAddresses;
                emails.add(emailItem);
            }

            skedEmailService service = new skedEmailService();
            service.sendEmails(emails);
        }
    }

    public void finish(Database.BatchableContext BC) {}
}