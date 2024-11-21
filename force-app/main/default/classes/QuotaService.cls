public with sharing class QuotaService {
    @AuraEnabled
    public static QuotaResponse getQuota(String periodId) {
        QuotaResponse theResponse = new QuotaResponse();
        List<Period> periods;

        if (String.isBlank(periodId)) {
            // Retrieve the current Period
            periods = [ select FullyQualifiedLabel,
                               startDate,
                               endDate
                          from Period
                         where startDate <= :System.today() 
                           and endDate >= : System.today()
                           and isForecastPeriod = true ];        
        } else {
            periods = [ select FullyQualifiedLabel,
                               startDate,
                               endDate
                          from Period
                         where id = :periodId ];            
        }

        if (!periods.isEmpty()) {
            theResponse.periodLabel = periods[0].FullyQualifiedLabel;
            theResponse.periodId = periods[0].id;
            theResponse.startDate = periods[0].startDate;
            theResponse.endDate = periods[0].endDate;

            // Retrieve current Quota
            List<ForecastingQuota> quotas = [ select quotaQuantity
                                                from ForecastingQuota
                                               where QuotaOwnerId = :UserInfo.getUserId()
                                                 and PeriodId = : periods[0].id];
        
            if (!quotas.isEmpty()) {
                theResponse.salesQuota = quotas[0].quotaQuantity.format();
            }

            // retrieve opportunities for forecast / actuals
            Decimal salesActual = 0;
            Decimal salesForecast = 0;

            for (Opportunity theOpportunity : [ select TotalOpportunityQuantity, 
                                                       Probability 
                                                  from Opportunity 
                                                 where ownerId = :UserInfo.getUserId() 
                                                 and closeDate >= :periods[0].startDate 
                                                 and closeDate <= :periods[0].endDate 
                                                  ]) {
                if (theOpportunity.TotalOpportunityQuantity != null) {
                    salesForecast += theOpportunity.TotalOpportunityQuantity;
                    salesActual += (theOpportunity.TotalOpportunityQuantity * (theOpportunity.Probability / 100));
                }
            }

            theResponse.salesForecast = salesForecast.format();
            theResponse.salesActual = salesActual.format();
        }

        return theResponse;
    }

    @AuraEnabled
    public static QuotaResponse getNextQuota(String periodId) {
        String nextPeriodId = periodId;

        if (String.isNotBlank(periodId)) {
            List<Period> cperiod = [ select startDate
                                       from Period
                                    where id = :periodId ]; 
             
             if (!cperiod.isEmpty()) {
                List<Period> periods = [ select Id
                                           from Period
                                          where startDate > :cperiod[0].startDate
                                            and isForecastPeriod = true 
                                            order by startDate
                                            limit 1 ];
                if (!periods.isEmpty()) {
                    nextPeriodId = periods[0].id;
                }  
             }            
        }

        return getQuota(nextPeriodId);
    }

    @AuraEnabled
    public static QuotaResponse getPreviousQuota(String periodId) {
        String nextPeriodId = periodId;

        if (String.isNotBlank(periodId)) {
            List<Period> cperiod = [ select startDate
                                       from Period
                                    where id = :periodId ]; 
             
             if (!cperiod.isEmpty()) {
                List<Period> periods = [ select Id
                                           from Period
                                          where startDate < :cperiod[0].startDate
                                            and isForecastPeriod = true 
                                            order by startDate desc
                                            limit 1 ];
                if (!periods.isEmpty()) {
                    nextPeriodId = periods[0].id;
                }  
             }            
        }

        return getQuota(nextPeriodId);
    }    

    class QuotaResponse {
        @AuraEnabled
        public String salesQuota = '0';
        @AuraEnabled
        public String salesForecast = '0';
        @AuraEnabled
        public String salesActual = '0';
        @AuraEnabled
        public String periodLabel = '???'; 
        @AuraEnabled
        public Id periodId;  
        @AuraEnabled
        public Date startDate;
        @AuraEnabled
        public Date endDate;        
    }
}