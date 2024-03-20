public class skedResourceTagHandler_Cache {
    
    private static sked__Tag__c traineeTag;
    public static sked__Tag__c getTraineeTagFromCache() {
        if (traineeTag == null) {
            traineeTag = [SELECT Id, Name FROM sked__Tag__c WHERE Name = :skedConstants.TAG_TRAINEE LIMIT 1];
        }

        return traineeTag;
    }

    private static sked__Tag__c noTraineeTag;
    public static sked__Tag__c getNoTraineeTagFromCache() {
        if (noTraineeTag == null) {
            noTraineeTag = [SELECT Id, Name FROM sked__Tag__c WHERE Name = :skedConstants.TAG_NO_TRAINEE LIMIT 1];
        }

        return noTraineeTag;
    }

    private static sked__Tag__c teamSupervisorTag;
    public static sked__Tag__c getTeamSupervisorTag() {
        if (teamSupervisorTag == null) {
            teamSupervisorTag = [SELECT Id, Name FROM sked__Tag__c WHERE Name = :skedConstants.TAG_TEAM_SUPERVISOR LIMIT 1];
        }

        return teamSupervisorTag;
    }

    private static sked__Tag__c driveLeadTag;
    public static sked__Tag__c getDriveLeadTag() {
        if (driveLeadTag == null) {
            driveLeadTag = [SELECT Id, Name FROM sked__Tag__c WHERE Name = :skedConstants.TAG_DRIVE_LEAD LIMIT 1];
        }

        return driveLeadTag;
    }
}