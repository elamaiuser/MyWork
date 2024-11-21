global class skedRecurringScheduleService extends skedDataService {
    
    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'sked__Recurring_Schedule__c';
        this.objectTYpe = 'recurringSchedule';
        this.domainType = Type.forName('skedModels.recurringSchedule');
    }
    
    protected virtual override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    global class queryModel extends skedDataService.queryModelBase {
        
    }

}