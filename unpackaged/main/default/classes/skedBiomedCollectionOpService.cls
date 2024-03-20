global class skedBiomedCollectionOpService extends skedDataService {

    /*********************************************************** Protected ***********************************************************/
    protected virtual override void initialize() {
        this.sObjectApiName = 'Biomed_Collection_Op_Center__c';
        this.objectTYpe = 'biomedCollectionOp';
        this.domainType = Type.forName('skedModels.biomedCollectionOp');
    }
    
    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (query.includes(skedSObjectType.REGION)) {
            skedQueryBuilder regionBuilder = query.getQueryBuilder('sked__Region__c');
        }
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedDataService.queryModelBase {
        
    }
    
}