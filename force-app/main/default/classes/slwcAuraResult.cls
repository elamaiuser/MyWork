global class slwcAuraResult {
    @AuraEnabled public boolean success {get;set;}
    @AuraEnabled public object returnedData {get;set;}
    @AuraEnabled public string message {get;set;}
}