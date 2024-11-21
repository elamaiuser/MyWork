/***
 * 
 * Controller for Lead form LSL Con
 * 
 * Update history
 * HRP- 9328- Anil K-> Use taxonomy record for zip code to city and state mapping, if no taxonomy record, check in collections territory
 * HRP-9370 - Anil K-> Switch sitekey and secrets to custom labels 
 * HRP-11743-Anil K->Campaign Tracking Not Working as Excepted
 * HRP-12024-Anil K-> Check Future Taxonomy records if a particular zip code is falling in non collection area *
 * HRP-13011-Apurba Bhattacharjee-> Lead intake form error message for NCA and invalid zip codes
 * **/
public class LeadFormLSLCon {
    
    public Lead newLead {get;set;}
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String title {get;set;}
    public String email {get;set;}
    public String phone {get;set;}
    public String street {get;set;}
    public String city {get;set;}
    public String stateCode {get;set;}
    public String companyName {get;set;}
    public String studentType {get;set;}
    public String zipCode {get;set;}
    public String currentDonor {get;set;}
    public Boolean showForm {get;private set;}
    public Boolean areaServed {get;private set;}
    public Boolean passedCaptcha {get; private set;}//Story AS-001540
    public Boolean captchaMsg {get; private set;} //Story AS-001540
    public Boolean validFirstName {get; private set;}
    public Boolean validLastName {get; private set;}
    public Boolean validCompanyName {get;private set;}
    public Boolean validEmail {get;private set;}
    public Boolean validPhone {get;private set;}
    public Boolean validCity {get;private set;}
    public Boolean validStudentType {get;private set;}
    public Boolean validCurrentDonor {get; private set;}
    public Boolean validAgeGroup {get;private set;}
    public Boolean validHostedBefore {get;private set;}
    public Boolean validPersonalStory {get;private set;}
    public Boolean validZip {get; private set;}
    public Boolean hasValidationErrors {get; private set;}
    public List<String> validationErrors {get;private set;}
	public Collections_Territory__c territory {get;private set;}
    public Boolean validPhoneType {get; private set;} //JIRA-8434

    
    // Adobe/Google tracking tags
    public String cmpId {get;set;}
    public String cidId {get;set;} 
    public String medId {get;set;}
    public String sourceId {get;set;} 
    public String did {get;set;}
    public String bid {get;set;}
    public String subj {get;set;}
    public String prty {get;set;}
    public String nat {get;set;}
    public String prod {get;set;}
    public String send {get;set;}
    public String delvid {get;set;}

    
    private String recordTypeID;
	private String campaignId;
    

    // Added by Ivo 5/9/17
    //Story AS-001540 
    private string baseURL = 'https://www.google.com/recaptcha/api/siteverify';
    private string secret = Label.RecaptchaSecretKey; //HRP-9370 - Anil K-> Switch sitekey and secrets to custom labels 
    
     
    public string siteKey { get { return Label.RecaptchaSiteKey  ;}} //HRP-9370 - Anil K-> Switch sitekey and secrets to custom labels 
    public Boolean isSandbox {get; private set;}




    // Constructor
    public LeadFormLSLCon() {
        
        isSandbox = [SELECT Id, IsSandbox  FROM Organization].isSandbox; // Used in VF to determine which Adobe Tag to render
        recordTypeID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('LSL').getRecordTypeId();

        // instantiate a new Lead object
        newLead = new Lead(
            LeadSource='LSL',
            CountryCode = 'US',
            Company_Type__c = 'Education',
            RecordTypeID = recordTypeID
        );
        
        //checkCampaignSource();

        zipCode = '';
        showForm = true; // default
        areaServed = false; // default
        
        resetDisplay();
        resetValidation();

    }
    
    // If a campaign id was passed to this form, validate it and attach the Lead to it.
    private void checkCampaignSource(){//String tempCmp, String tempCid, String tempMed, String tempSource){ // updated by Ivo 1/22/19
        if(did ==null){
            return;
        }

        List<Campaign> cmpResults = CampaignService.findByField('External_Did__c', String.escapeSingleQuotes(did.trim()));//HRP 11743- trim string 
            
        if(!cmpResults.isEmpty()){
            System.debug('FOUND CAMPAIGN: ' + cmpResults[0]);
            campaignId = cmpResults[0].Id;
        } else {
            System.debug('NO CAMPAIGN FOUND FOR LEAD');
        }
        
    }
    
    
    private void resetDisplay(){
        showForm = true;
        validZip = true;
        passedCaptcha = false; // Added by Ivo 5/9/17 Story AS-001540 
    }


    

   	/**
	 * HRP-93298 add city and state to taxonomy and use taxonomy record
	 * over collections terriotory when it is available, otherwise fall back on collections zip record
	 * HRP-12024-> Check Future Taxonomy records if a particular zip code is falling in non collection area and remove reference to collections territory 
	 * */
    public PageReference validateZipcode(){
        
        // If Captcha is not valid, stop everything and present an error message..
        if(!isCaptchaValid()){
            System.debug('WHOA! CAPTCHA FAILED!!');
            System.debug('newLead.PostalCode 2 = ' + newLead.PostalCode);
          System.debug('ValidZip Captcha FAIL 2 = ' + validZip);
           return null; // keep them on the page
        } else {
            
            System.debug('Captcha is valid, checking zipcode..'); // During development, it's good to add this kind of debugging just so you know when something DID work correctly..
        }
        
        System.debug('CampaignID: ' + this.cmpId);
        System.debug('CampaignSource1: ' + this.sourceId);
        System.debug('Incoming DID: ' + this.did);

		checkCampaignSource();//this.cmpId, this.cidId, this.medId, this.sourceId);  // updated by Ivo 1/22/19      
        
        System.debug('Checking zip code: ' + newLead.PostalCode);

        zipCode = newLead.PostalCode;

        List<Taxonomy__c> futureTaxonomyresults = new List<Taxonomy__c>();
        // HRP- 9328 Begin (Use taxonomy record for zip code to city and state mapping, if no taxonomy record, check in collections territory)
        Date thisDate = Date.today();
        String taxonomyBioSFRecordType = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_COLLECTION_RECORD_TYPE).getRecordTypeId();
		String nonServiceArea='Non-Collection Area';
        // HRP-13011--> Start
        List<Taxonomy__c > taxonomyRecord = [SELECT Id,RecordTypeId, Name, City__c, State__c,Collection_Operation_Name__c 
                                              FROM Taxonomy__c WHERE RecordTypeId=:taxonomyBioSFRecordType AND City__c!=null AND State__c != null AND Zip_Code__c = :zipCode];
        //invalid input
        if(taxonomyRecord.isEmpty()){
            System.debug('No results for ' + zipCode);
            validZip = false;
            return null;
        }else {
            //zip code valid and it's a current ARC service area
            List<Taxonomy__c > taxonomyResults = [SELECT Id,RecordTypeId, Name, City__c, State__c,Collection_Operation_Name__c  FROM Taxonomy__c WHERE RecordTypeId=:taxonomyBioSFRecordType AND Start_Date__c < :thisDate and End_Date__c >= :thisDate AND Zip_Code__c = :zipCode 
                                              AND City__c!=null AND State__c != null AND (Collection_Operation_Name__c != :nonServiceArea AND District_Name__c != :nonServiceArea 
                                              AND Division_Name__c != :nonServiceArea AND DS_Region_Name__c != :nonServiceArea)];
            System.debug('taxonomyResults size->'+taxonomyResults.size());
            if(taxonomyResults.isEmpty()){
                //HRP-12024--> Check Future Taxonomy records if a particular zip code is falling in non collection area
                futureTaxonomyresults = [SELECT Id,RecordTypeId, Name, City__c, State__c,Collection_Operation_Name__c  FROM Taxonomy__c WHERE RecordTypeId=:taxonomyBioSFRecordType AND Start_Date__c >= :thisDate and End_Date__c > :thisDate and Zip_Code__c = :zipCode 
                                        AND City__c!=null AND State__c != null AND Collection_Operation_Name__c != :nonServiceArea AND District_Name__c != :nonServiceArea 
                                        AND Division_Name__c != :nonServiceArea AND DS_Region_Name__c != :nonServiceArea];
                System.debug('Future Taxonomy records Result size for ' + zipCode + ': ' + futureTaxonomyresults.size());
            }// HRP-13011--> End
            if(taxonomyResults.isEmpty() && futureTaxonomyresults.isEmpty()){
                System.debug('No results for ' + zipCode);
                territory = null;
                areaServed = false; // just because the zip code isn't in the database, doesn't mean we don't serve this area.
                validZip = true;
            } else {
                Taxonomy__c taxonomy = (taxonomyResults != null && taxonomyResults.size()>0)? taxonomyResults[0]:futureTaxonomyresults[0];//HRP-12024
                areaServed = true;
                String city = 	taxonomy !=null ? taxonomy.City__c :territory.City__c;           
                String stateCode = 	taxonomy !=null ? taxonomy.State__c :territory.State_Code__c;           
                // HRP- 9328 End
                newLead.City = city;
                newLead.StateCode = stateCode;
                stateCode = stateCode;
                showForm = true;
                validZip = true;
            }
        }
           
        return null;
    }

	/*
    private Boolean isValidEmail(string email){

        if(String.isEmpty(email)) return false;

        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,6}|[0-9]{1,3})';
        Pattern MyPattern = Pattern.compile(emailRegex);

        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) {
            system.debug('not a valid email: ' + email);
            return false;
        } else {
            system.debug('valid email: ' + email);
            return true;
        }

    }


    private Boolean isValidPhone(string phone){
        //(\\D?[0-9]{3}\\D?)[\\s][0-9]{3}-[0-9]{4}
        if(String.isEmpty(phone)) return false;

        String phoneRegex = '[0-9]{3}-[0-9]{3}-[0-9]{4}';
        Pattern MyPattern = Pattern.compile(phoneRegex);

        // Then instantiate a new Matcher object "MyMatcher"
        Matcher MyMatcher = MyPattern.matcher(phone);

        if (!MyMatcher.matches()) {
            system.debug('not a valid phone: ' + phone);
            return false;
        } else {
            system.debug('valid phone: ' + phone);
            return true;
        }
        return true;
    }
	*/

    public List<SelectOption> getStateOpts(){

        List<SelectOption> opts = new List<SelectOption>();
        
        // Use getDescribe() to find the Lead object's StateCode options
        Schema.DescribeFieldResult fieldResult = Lead.StateCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        // default first option
        opts.add(new SelectOption('Please select', '')); 

        // Add an option for each value
        for(Schema.PicklistEntry f : ple){
            opts.add(new SelectOption(f.getValue(),f.getLabel()));
        }


        return opts;
    }

    
    public PageReference saveLead(){

        resetValidation();

        if(!formIsValid()){
            System.debug('There are ' + validationErrors.size() + ' validation errors.');
            hasValidationErrors = true; // this will toggle the outputPanel on the page to show the errors section
            return null;
        } else { System.debug('There are no validation errors, form is valid.'); }
        
        try{

            newLead.FirstName = firstName;
            newLead.LastName = lastName;
            newLead.Title = title;
            newLead.Email = email;
            newLead.Phone = FormUtils.cleanPhone(phone);
            newLead.Company = companyName;
            newLead.Lead_Status_NEW__c = DateTime.now();
            newLead.Initial_New_Lead_Status__c = DateTime.now();
            if(campaignId != null){
                
                List<Campaign> campaignList  = CampaignService.findByField('Id', campaignId);
                if(campaignList !=null && campaignList.size()>0){
					 Campaign campaignFrom = campaignList.get(0);
                     newLead.Campaign_Name__c = campaignFrom.name;
                	 newLead.Parent_Campaign__c = campaignFrom.ParentId;
                	 newLead.External_Campaign_ID__c = campaignFrom.External_Campaign_Id__c;
               		 newLead.External_Med__c = campaignFrom.External_Med__c;
                	 newLead.Campaign_Status__c = campaignFrom.Status;
                }
            }
            


            System.debug('New Lead record type: ' + newLead.RecordTypeID);

            // DML Options to send normal lead notification emails, avoid duplicate rule issues, and observe defined Lead Assignment rules for queues
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.allowSave = true;
            dmlOpts.assignmentRuleHeader.useDefaultRule= true;
            dmlOpts.EmailHeader.triggerUserEmail = true; 
            dmlOpts.EmailHeader.triggerAutoResponseEmail = true;


            // Save the Lead record using the DML Options defined above
            Database.SaveResult sr = Database.insert(newLead, dmlOpts);


            // Check that the record was saved successfully
            if (sr.isSuccess()) {
                System.debug('Lead inserted: ' + newLead);
                showForm=false;
                
                // If a "cid" (Campaign ID) was passed in the url, add the lead to the Campaign
                if(campaignId != null){
                    addLeadToCampaign();
                }    
                
                // Redirect to the confirmation page..
                // Updated Page.LeadFormComplete to Page.LeadFormLSLComplete so when the LSL lead form is submitted it points to the new confirmation page - Denise 1-8-18
                PageReference nextPg = Page.LeadFormLSLComplete;
                nextPg.setRedirect(true);
                return nextPg;

            } else {
                System.debug(LoggingLevel.ERROR,'Insert not successful: ' + sr.getErrors()[0].getMessage());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem saving your information, the System Administrator has been informed of the problem.' + sr.getErrors()[0].getMessage()));
            }

        } catch (DmlException e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error saving your information: ' + e.getDmlMessage(0)));}
        
        
        return null;

    }
    
    
    private void addLeadToCampaign(){
        CampaignMember cm = new CampaignMember(
            CampaignId = this.campaignId,
            LeadId = this.newLead.Id
        );
        try{
            insert(cm);
        } catch (DmlException e){
            System.debug('Error creating new CampaignMember record: ' + e.getMessage());
        }
    }



    private void resetValidation(){
        validFirstName = true;
        validLastName = true;
        validCompanyName = true;
        validEmail = true;
        validPhone =true;
        validCity = true;
        validStudentType = true;
        validAgeGroup = true;
        /*validCompanySubType =true;
        validCompanySubTypeOther = true;
        validCompanySize = true;*/
        validHostedBefore = true;
        validCurrentDonor = true;
        validPersonalStory = true;
        validZip = true;
        validPhoneType= true; //JIRA-8434
        hasValidationErrors = false;
    }

    @TestVisible
    private Boolean formIsValid(){

        // Reset the validationErrors list each time we check the form
        validationErrors = new List<String>();


        // First Name
        if( String.isBlank(firstName) ){
            validationErrors.add('Please enter a First Name');
            validFirstName = false;
        } 

        // Last Name
        if( String.isBlank(lastName)){
            validationErrors.add('Please enter a Last Name');
            validLastName = false;
        } 

        // Age Group
        if(newLead.Age_Group__c == null){
            validationErrors.add('Please specify your Age Group');
            validAgeGroup = false;
        }

        // School/Institution Name
        if( String.isBlank(companyName)){ 
            validationErrors.add('Please enter an School/Instituition Name');
            validCompanyName = false;
        }

        // Current Donor
        if( newLead.Current_Blood_Donor__c == null ){ 
            validationErrors.add('Please specify whether or not you are a current blood donor');
            validCurrentDonor = false;
        }

        // Student Type
        if( newLead.Student_Type__c == null ){ 
            validationErrors.add('Please specify whether you are a High School or College student');
            validStudentType = false;
        }

        // Email
        if( !FormUtils.isValidEmail(email) ){
            validationErrors.add('Please enter a valid Email address');
            validEmail = false;
        }

        // Phone
        if( !FormUtils.isValidPhone(phone) ){ 
            validationErrors.add('Please enter a valid Phone number');
            validPhone = false;
        }
        
        // phoneType -JIRA-8434
        if( String.isBlank(newLead.Phone_Type__c)){
            validationErrors.add('Please pick valid Phone Type.');
            validPhoneType = false;
        }
        


        // Hosted Before
        if( newLead.Hosted_Before__c == null){
            validationErrors.add('Please select a response for \'Have you or your institution hosted a blood drive with the Red Cross before?\'');
            validHostedBefore = false;
        }

        // Has Personal Story
        if( newLead.Has_Personal_Story__c == null){
            validationErrors.add('Please select a response for \'Do you have a reason or personal story that motivated you and/or your organization to host this blood drive?\'');
            validPersonalStory = false;
        }

        /*
        // Has Personal Story and provided a description 
        if( newLead.Has_Personal_Story__c == 'Yes' && String.isBlank(newLead.Comments__c)){
            validationErrors.add('Please tell us about your personal story');
            validPersonalStory = false;
        }
        */

        System.debug('There are ' + validationErrors.size() + ' validation errors in formIsValid().');

        // if there are no errors in validationErrors, the form is valid..
        return validationErrors.isEmpty();
    }


        
    //    
    //Recaptcha
    //
    private Boolean isCaptchaValid(){
        
        // Set a default for passedCaptcha (this helps test coverage since there is less code in the "else" statement below that will be hard 
        // to execute from a test.)
        passedCaptcha = false;
        
        // Get the captcha response in the querystring
        String captchaResponse = ApexPages.currentPage().getParameters().get('g-recaptcha-response');
        String responseBody=makeRequest(baseUrl,'secret=' + secret +'&response=' + captchaResponse );
        String success = getValueFromJson(responseBody,'success');
        System.debug('Recaptcha result: '  + success);
        
        // Add a condition to check if this controller code is being executed as a result of a unit test, if it is, we 
        // want to just assume that Google is working and captcha returned a successful response..
        if(success.equalsIgnoreCase('true') || Test.isRunningTest()){ 
            passedCaptcha = true;
        } else {
            captchaMsg = true;
        }
        
        // Just return the value of passedCaptcha here instead of true/false (helps with code coverage)
        return passedCaptcha;
    }
        
        
    /**
    * Make request to verify captcha
    * @return      response message from google
    */
    private static String makeRequest(string url, string body)  {
        
        HttpResponse response = null;
        HttpRequest req = new HttpRequest();   
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setBody (body);
        
        try {
            Http http = new Http();
            response = http.send(req);
            return response.getBody();
        } catch(System.Exception e) {
            System.debug('ERROR: ' + e);
        }
        return '{"success":false}';
    }   
    
   
    /**
      * to get value of the given json string
      * @params      
      *  - strJson       json string given
      *  - field         json key to get the value from
      * @return          string value
    */
    public static string getValueFromJson ( String strJson, String field ){
        JSONParser parser = JSON.createParser(strJson);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                if(parser.getText() == field){
                    // Get the value.
                    parser.nextToken();
                    return parser.getText();
                }
            }
        }
        return null;
    }


}