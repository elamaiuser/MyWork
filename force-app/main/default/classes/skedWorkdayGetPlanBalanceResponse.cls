public class skedWorkdayGetPlanBalanceResponse extends skedWorkdayApiResponse {
    @AuraEnabled public Map<String, timeOffPlan> timeOffPlansByLabel;
        
    public Decimal totalBalance {
        get {
            Decimal totalBalance = 0;
            for (timeOffPlan plan : this.timeOffPlans) {
                if (plan != null) {
                    totalBalance += plan.balance;
                }
            }
            return totalBalance;
        }
    }

    @AuraEnabled public List<timeOffPlan> timeOffPlans {
        get {
            return this.timeOffPlansByLabel.values();
        }
    }

    public skedWorkdayGetPlanBalanceResponse(String request) {
        super(request);
        this.timeOffPlansByLabel = new Map<String, timeOffPlan>{
            skedConstants.AVAILABILITY_TYPE_PTO => null,
            skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY => null,
            skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT => new timeOffPlan(skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT, 0),
            skedConstants.UNAVAILABILITY_TYPE_PERSONAL => null,
            skedConstants.UNAVAILABILITY_TYPE_SICK => null
        };
    }

    public override String toString() {
        return 'Total Balance: ' + this.totalBalance + 
        '\nTime Off Plans By Label : ' + timeOffPlansByLabel;
    }
    
    public class timeOffPlan {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal balance;
        @AuraEnabled public List<timeOffReason> timeOffReasons;

        public timeOffPlan(String name, Decimal balance) {
            this.name = name;
            this.balance = balance;
            this.timeOffReasons = new List<timeOffReason>();
        }

        public timeOffPlan clone(String name) {
            timeOffPlan clonedPlan = new timeOffPlan(name, this.balance);
            clonedPlan.timeOffReasons = this.timeOffReasons;
            return clonedPlan;
        }
    }

    public class timeOffReason {
        @AuraEnabled public String name;
        @AuraEnabled public String reasonId;
        @AuraEnabled public Boolean isDefault;

        public timeOffReason(String name, String reasonId, Boolean isDefault) {
            this.name = name;
            this.reasonId = reasonId;
            this.isDefault = isDefault;
        }
    }
}