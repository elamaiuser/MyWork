public class skedCustomNotificationService extends skedNotificationService {
    private List<String> settingNames;
    public skedCustomNotificationService(List<String> settingNames) {
        this.settingNames = settingNames;
    }

    protected override void buildQueryConditionsToFetchNotificationSettings(skedQueryBuilder queryBuilder) {
        queryBuilder.addCondition('DeveloperName IN {0}', this.settingNames);
        queryBuilder.addCondition('sked_Trigger__c = \'Custom\'');
    }
}