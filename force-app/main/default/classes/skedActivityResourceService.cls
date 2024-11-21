global class skedActivityResourceService extends skedDataService {

    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'sked__Activity_Resource__c';
        this.objectTYpe = 'activityResource';
        this.domainType = Type.forName('skedModels.activityResource');
    }
    
}