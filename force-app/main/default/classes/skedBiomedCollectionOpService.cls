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
        List<String> excludedCONames = new List<String>{skedConstants.NON_COLLECTION_AREA_CO};
        queryBuilder.addCondition('(Name NOT IN {0})', excludedCONames);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedDataService.queryModelBase {
        
    }
    
}