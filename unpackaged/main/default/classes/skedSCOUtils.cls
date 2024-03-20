public class skedSCOUtils {

    public static Map<Id, List<sked_Site_Collection_Operation__c>> getScosByCoIds(List<ScoQueryModel> queryModels) {
        skedQueryBuilder queryBuilder = new skedQueryBuilder();
        queryBuilder.setFromClause('sked_Site_Collection_Operation__c');
        queryBuilder.setIsOrQuery(true);
        queryBuilder.addFields(new List<String>{
            'Id', 'sked_Start_Date__c', 'sked_End_Date__c', 'sked_Collection_Operation__c', 'sked_Site__r.sked__GeoLocation__c'
        });
        
        for (ScoQueryModel queryModel : queryModels) {
            String collectionOpCondition = queryBuilder.generateCondition('sked_Collection_Operation__c = {0}', queryModel.coId);
            String startDateCondition = queryBuilder.generateCondition('sked_Start_Date__c <= {0}', queryModel.endDate);
            String endDateCondition = queryBuilder.generateCondition('sked_End_Date__c >= {0}', queryModel.startDate);
                    
            queryBuilder.addConditionGroup(new List<String>{collectionOpCondition, startDateCondition, endDateCondition});
        }


        Map<Id, List<sked_Site_Collection_Operation__c>> scosByCoId = new Map<Id, List<sked_Site_Collection_Operation__c>>();
        for (sked_Site_Collection_Operation__c sco : Database.query(queryBuilder.toString())) {
            List<sked_Site_Collection_Operation__c> scos = scosByCoId.get(sco.sked_Collection_Operation__c);

            if (scos == null) {
                scos = new List<sked_Site_Collection_Operation__c>();
            }

            scos.add(sco);
            scosByCoId.put(sco.sked_Collection_Operation__c, scos);
        }

        return scosByCoId;
    }
    
    public class ScoQueryModel {
        public Id coId;
        public Date startDate;
        public Date endDate;

        public ScoQueryModel(Id coId, Date startDate, Date endDate) {
            this.coId = coId;
            this.startDate = startDate == null ? skedConstants.EARLIEST_START_DATE : startDate;
            this.endDate = endDAte == null ? skedConstants.LATEST_END_DATE : endDate;
        }
    }
}