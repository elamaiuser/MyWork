global class skedActivityCollectionOperationService extends skedEventService {

    protected override void initialize() {
        this.sObjectApiName = 'sked_Activity_Collection_Operation__c';
        this.objectTYpe = 'activityCollectionOperation';
        this.domainType = Type.forName('skedModels.activityCollectionOperation');
    }
    
}