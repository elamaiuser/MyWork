global class skedEmailService {
    
    private Map<string, Id> map_templateApiName_Id;
    private Map<string, Id> map_orgEmailAddress_Id;
    
    public skedEmailService() {
        this.map_templateApiName_Id = new Map<string, Id>();
        this.map_orgEmailAddress_Id = new Map<string, Id>();
    }
    
    public void sendEmails(List<emailModel> models) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<String> templateApiNames = new List<String>();
		for(emailModel model : models){
			templateApiNames.add(model.templateApiName);
		}
        
		if (!templateApiNames.isEmpty()){
			List<EmailTemplate> emailTemplates =[SELECT Id, DeveloperName 
                                                 FROM EmailTemplate 
                                                 WHERE DeveloperName In :templateApiNames];
            for (EmailTemplate template : emailTemplates){
                map_templateApiName_Id.put(template.DeveloperName, template.Id);
            }
		}
        for (emailModel model : models) {
            Messaging.SingleEmailMessage email = generateEmail(model);
            emailList.add(email);
        }
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(emailList);
        }
    }
    
    /*********************************************************** Private methods clases *****************************************************/
    private Messaging.SingleEmailMessage generateEmail(emailModel model) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(model.targetObjId);
        if (!string.isBlank(model.fromAddress)) {
            Id orgWideEmailId;
            if (!map_orgEmailAddress_Id.containsKey(model.fromAddress)) {
                List<OrgWideEmailAddress> orgEmailResult = [SELECT Id, Address 
                                                            FROM OrgWideEmailAddress
                                                            WHERE Address = :model.fromAddress];
                if (!orgEmailResult.isEmpty()) {
                    orgWideEmailId = orgEmailResult.get(0).Id;
                }
                map_orgEmailAddress_Id.put(model.fromAddress, orgWideEmailId);
            }
            orgWideEmailId = map_orgEmailAddress_Id.get(model.fromAddress);
            if (orgWideEmailId != NULL) {
                email.setorgWideEmailAddressId(orgWideEmailId);
            }
        }
		if (!string.isBlank(model.templateApiName)) {
			if (map_templateApiName_Id.containsKey(model.templateApiName)) {
                email.setTemplateId(map_templateApiName_Id.get(model.templateApiName));
			}
			
		}
        if (!string.isBlank(model.subject)) {
            email.setSubject(model.subject);
        }
        if (!string.isBlank(model.htmlBody)) {
            email.setHtmlBody(model.htmlBody);
        }
        if (model.whatId != NULL) {
            email.setWhatId(model.whatId);
        }
        if (model.toList != NULL && !model.toList.isEmpty()) {
            email.setToAddresses(model.toList);
        }
        email.setSaveAsActivity(model.saveAsActivity);
		
        return email;
    }
    
    /*********************************************************** Nested clases *****************************************************/
    public class emailModel {
        public string fromAddress;
        public List<string> toList;
        public string subject;
        public string htmlBody;
        public Id targetObjId;
        public Id whatId;
        public boolean saveAsActivity;
		public string templateApiName;
        
        public emailModel() {
            this.saveAsActivity = false;
            this.toList = new List<string>();
        }
    }
    
}