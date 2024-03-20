public with sharing class RenderSitePlanController {

   @AuraEnabled
   public static String getImage(Id templateId){
       AzureSitePlanCredentials__c customSitePlan = AzureSitePlanCredentials__c.getValues('Site plan');
       System.debug(customSitePlan);
       if (customSitePlan != null && customSitePlan.EndPoint__c != null && customSitePlan.Key__c != null && templateId != null) {
           Http http = new Http();
           HttpResponse res = new HttpResponse();
           HttpRequest req = new HttpRequest();
           
           //templateId = '0068I000002pBodQAE';
           req.setEndpoint(customSitePlan.EndPoint__c);
           req.setMethod('POST');
           req.setBody('{\"SalesForceId\":'+'\"'+templateId+'\"}');
           req.setHeader('Content-Type', 'application/json');  
           req.setHeader('x-functions-key', customSitePlan.Key__c);
           req.setHeader('Accept', '/'); 
           res = http.send(req);
           
           Map<String, String> response = new  Map<String, String>();
            if (res.getStatusCode() == 200) {
                response = (Map<String, String>)JSON.deserialize(res.getBody(), Map<String, String>.class);
                return response.get('image');
            } else if (res.getStatusCode() == 400) {
                return 'No Site Plan found!';
            }
       }
       return null;
    }

    @AuraEnabled
    public static String getOperationTemplateId(String operationRecId){
        List <sked_Operation_Record__c> operations = [SELECT Id, Name, sked_Drive__r.sked_Opportunity__r.Parent_Template_Id__c FROM sked_Operation_Record__c WHERE Id =: operationRecId];
        if(operations != null && operations[0].sked_Drive__r != null && operations[0].sked_Drive__r.sked_Opportunity__r !=  null && operations[0].sked_Drive__r.sked_Opportunity__r.Parent_Template_Id__c != null){     
            return operations[0].sked_Drive__r.sked_Opportunity__r.Parent_Template_Id__c;
        }
        return null;
    }
}