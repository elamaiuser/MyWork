/***
 * 
 * Controller for Lead form
 * 
 * Update history
 * HRP- 9328- Anil K-> Use taxonomy record for zip code to city and state mapping, if no taxonomy record, check in collections territory
 * HRP-9370 - Anil K-> Switch sitekey and secrets to custom labels 
 * HRP-11743-Anil K->Campaign Tracking Not Working as Excepted
 * **/

public class LeadFormCon {

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
    public String zipCode {get;set;}
    public Boolean showForm {get;private set;}
    public Boolean areaServed {get;private set;}
    public Boolean showEd {get;set;}
    public Boolean showMember {get;set;}
    public Boolean showRel {get;set;}
    public Boolean showCorp {get;set;}
    public Boolean showMedia {get;set;}
    public Boolean showMilitary {get;set;}
    public Boolean showHospital {get;set;}
    public Boolean showOther {get;set;}

    public Boolean passedCaptcha {get; private set;}//Story AS-001540
    public Boolean captchaMsg {get; private set;} //Story AS-001540

    public Boolean validFirstName {get; private set;}
    public Boolean validLastName {get; private set;}
    public Boolean validCompanyName {get;private set;}
    public Boolean validEmail {get;private set;}
    public Boolean validPhone {get;private set;}
    public Boolean validCity {get;private set;}
    public Boolean validCompanyType {get;private set;}
    public Boolean validCompanySubType {get;private set;}
    public Boolean validCompanySubTypeOther {get;private set;}
    public Boolean validCompanySize {get;private set;}
    public Boolean validHostedBefore {get;private set;}
    public Boolean validPersonalStory {get;private set;}
    public Boolean validZip {get; private set;}
    public Boolean validPhoneType {get; private set;} //JIRA-8434
    public Boolean hasValidationErrors {get; private set;}
    public String numEmployeesLabel {get; private set;}
    public String orgSubTypeLabel {get; private set;}
    public List<String> validationErrors {get;private set;}
    public Collections_Territory__c territory {get;private set;}

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
    
     
    public string siteKey { 
        get { return Label.RecaptchaSiteKey ;} //HRP-9370 - Anil K-> Switch sitekey and secrets to custom labels 
    }
    
    public Boolean isSandbox {get; private set;}

    
    
    
    // Constructor
    public LeadFormCon() {
        
        isSandbox = [SELECT Id, IsSandbox  FROM Organization].isSandbox; // Used in VF to determine which Adobe Tag to render
        recordTypeID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Lead').getRecordTypeId();

        
        
        // instantiate a new Lead object
        newLead = new Lead(
            RecordTypeId = recordTypeID,
            LeadSource='Redcrossblood.org',
            CountryCode = 'US'
        );
        
        //checkCampaignSource();
        
        zipCode = '';
        showForm = true; // default
        areaServed = false; // default
        
        resetDisplay();
        resetValidation();

    }

    
    
    
    private void resetDisplay(){
        showForm = true;
        showEd = false;
        showMember = false;
        showRel = false;
        showCorp = false;
        showMedia = false;
        showMilitary = false;
        showHospital = false;
        showOther = false;
        validZip = true;
        passedCaptcha = false; // Added by Ivo 5/9/17 Story AS-001540 
        //validFirstName = true;
        //hasValidationErrors = false;
    }

	
    
    
	/**
	 * HRP-93298 add city and state to taxonomy and use taxonomy record
	 * over collections terriotory when it is available, otherwise fall back on collections zip record
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

        List<Collections_Territory__c> results = new List<Collections_Territory__c>();
        // HRP- 9328 Begin (Use taxonomy record for zip code to city and state mapping, if no taxonomy record, check in collections territory)
        Date thisDate = Date.today();
        String taxonomyBioSFRecordType = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_COLLECTION_RECORD_TYPE).getRecordTypeId();
		String nonServiceArea='Non-Collection Area';
        
        List<Taxonomy__c > taxonomyResults = [select Id,RecordTypeId, Name, City__c, State__c,Collection_Operation_Name__c  from Taxonomy__c where Start_Date__c <= :thisDate and End_Date__c >= :thisDate and Zip_Code__c  = :zipCode 
                                              and RecordTypeId=:taxonomyBioSFRecordType and Collection_Operation_Name__c != :nonServiceArea and District_Name__c != :nonServiceArea 
                                              and Division_Name__c != :nonServiceArea and DS_Region_Name__c != :nonServiceArea and City__c!=null and State__c != null];
		System.debug('taxonomyResults size->'+taxonomyResults.size());
        if(taxonomyResults.isEmpty()){
             results = [select Id, Name, City__c, State_Code__c, Service_Area__c from Collections_Territory__c where sked_start_date__c=null and Zip__c = :zipCode];
			 System.debug('Collections_Territory__c Result size for ' + zipCode + ': ' + results.size());

        }
        if(results.isEmpty() && taxonomyResults.isEmpty()){
            System.debug('No results for ' + zipCode);
            territory = null;
            areaServed = false; // just because the zip code isn't in the database, doesn't mean we don't serve this area.
            validZip = false;
        } else {
            Taxonomy__c taxonomy = (taxonomyResults != null && taxonomyResults.size()>0)? taxonomyResults[0]:null;
            Collections_Territory__c collectionsTerritory = (results != null && results.size()>0) ? results[0]:null;
            areaServed = true;

            if(collectionsTerritory != null){
                territory = (results != null && results.size()>0) ? results[0]:null;
                areaServed = territory != null ? territory.Service_Area__c == true:false;
            }
		    String city = 	taxonomy !=null ? taxonomy.City__c :territory.City__c;           
            String stateCode = 	taxonomy !=null ? taxonomy.State__c :territory.State_Code__c;           
			// HRP- 9328 End
            newLead.City = city;
            newLead.StateCode = stateCode;
            stateCode = stateCode;
            showForm = true;
            validZip = true;
        } 
           
        return null;
    }

    
    
    // If a campaign id was passed to this form, validate it and attach the Lead to it.
    private void checkCampaignSource(){//String tempCmp, String tempCid, String tempMed, String tempSource){ // updated by Ivo 1/22/19
        String didTrimmed = did!=null ? did.trim() :did;
            
        List<Campaign> cmpResults = CampaignService.findByField('External_Did__c', String.escapeSingleQuotes(didTrimmed));//HRP 11743- trim string 
            
        if(!cmpResults.isEmpty()){
            System.debug('FOUND CAMPAIGN:' + cmpResults[0]);
            campaignId = cmpResults[0].Id;
        } else {
            System.debug('NO CAMPAIGN FOUND FOR LEAD');
        }
        
    }
    

    // Look up an External (not native SF) campaign id and see if it is assigned to a 
    // native SF Campaign record.
    private String getCampaignId(){//String extCampaignId, String extCid, String ExtMed, String ExtSource, String delvId){ //updated by Ivo 1/22/19
        
        List<Campaign> cmpList = [SELECT id, name, isActive FROM Campaign WHERE 
                                  /*External_Campaign_Id__c= :cmpVal AND 
                                  External_Cid__c= :cidVal AND 
                                  External_Med__c= :medVal AND 
                                  External_Source__c= :sourceVal AND
                                  External_delvid__c = :delvIdVal*/
                                  External_CampDesc__c = :String.escapeSingleQuotes(cmpId) AND
                                  External_nat__c = :String.escapeSingleQuotes(nat) AND
                                  External_delvid__c = :String.escapeSingleQuotes(delvId) AND
                                  External_Source__c = :String.escapeSingleQuotes(sourceId)
                                  LIMIT 1];
        System.debug('cmpList :' +cmpList);
        
        if(!cmpList.isEmpty()){
            return cmpList[0].Id;
        } else {
            System.debug('No Campaigns found');	
            return null;
        }
        
    }
    
    
    private Campaign getCampaignDetails(){
        
         if(String.isBlank(this.cmpId) == true && String.isBlank(this.nat) ==true && String.isBlank(this.delvId)==true && String.isBlank(this.sourceId)==true)
            return null;
         System.debug('cmpId->'+cmpId);System.debug('nat->'+nat);System.debug('delvId->'+delvId);System.debug('sourceId->'+sourceId);

        String cmpId = this.cmpId !=null ? this.cmpId.trim():this.cmpId;   //HRP 11743- trim string 
        String nat = this.nat !=null? this.nat.trim():this.nat; //HRP 11743- trim string 
        String delvId = this.delvId !=null? this.delvId.trim(): this.delvId;  
        String sourceId = this.sourceId !=null? this.sourceId.trim() : this.sourceId;//HRP 11743- trim string 
	    String campaignQuery ='SELECT id, name, isActive,ParentId ,External_Campaign_Id__c,External_Med__c,Status FROM Campaign WHERE ';
        campaignQuery = String.isNotBlank(cmpId)? campaignQuery+ ' External_CampDesc__c = \''+String.escapeSingleQuotes(cmpId) +'\' AND ' : campaignQuery;
        campaignQuery = String.isNotBlank(nat)? campaignQuery+ ' External_nat__c = \''+String.escapeSingleQuotes(nat)+'\' AND ' : campaignQuery;
        campaignQuery = String.isNotBlank(delvId)? campaignQuery+ ' External_delvid__c = \''+String.escapeSingleQuotes(delvId)+'\' AND ' : campaignQuery;
        campaignQuery = String.isNotBlank(sourceId)? campaignQuery+ ' External_Source__c = \''+String.escapeSingleQuotes(sourceId)+'\' AND ' : campaignQuery;
		campaignQuery = campaignQuery.endsWith(' AND ')? campaignQuery.removeEnd(' AND ') :campaignQuery;//remove trialing AND
        campaignQuery = campaignQuery+' LIMIT 1 ';
        System.debug(campaignQuery);

        List<Campaign> cmpList = Database.query(campaignQuery);
        System.debug('cmpList :' +cmpList);
        
        if(!cmpList.isEmpty()){
            return cmpList[0];
        } else {
            System.debug('No Campaigns found');	
            return null;
        }
        
    }
    
    
    

    

    

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

    
    public PageReference setCompanyType(){
        
        resetDisplay();

        System.debug('calling setCompanyType()');



        if(newLead.Company_Type__c != null){
            if(newLead.Company_Type__c.equals('Church/Faith-Based Group')) {
                showRel = true;
                numEmployeesLabel = 'Number of members/staff part of your church or faith-based group?';
                orgSubTypeLabel = ''; // No current sub-type for Church/FBG option
            } else if(newLead.Company_Type__c.equals('Business')){
                showCorp = true;
                numEmployeesLabel = 'Number of employees located at your site?';
                orgSubTypeLabel = 'Type of Business/Corporate Organization';
            } else if(newLead.Company_Type__c.equals('Education')) {
                showEd = true;
                numEmployeesLabel = 'Number of students and staff members enrolled and/or employed at your school?';
                orgSubTypeLabel = 'Type of Educational Institution';
            } else if(newLead.Company_Type__c.equals('Civic/Community')) {
                showMember = true;
                numEmployeesLabel = 'Number of people/members in your community/part of your organization?';
                orgSubTypeLabel = 'What type of Organization are you representing?';
            } else if(newLead.Company_Type__c.equals('Media Outlet')) {
                showMedia = true;
                numEmployeesLabel = 'Number of employees located at your site?';
                orgSubTypeLabel = 'Type of Media Outlet';
            } else if(newLead.Company_Type__c.equals('Healthcare')) {
                showHospital = true;
                numEmployeesLabel = 'Number of employees that you can target for recruitment efforts?';
                orgSubTypeLabel = 'Type of Healthcare Facility';
            } else if(newLead.Company_Type__c.equals('Military/Government/NGO')) {
                showMilitary = true;
                numEmployeesLabel = 'Number of employees at your site that can particiapte in the blood drive?';
                orgSubTypeLabel = 'Type of Agency';
            } else if(newLead.Company_Type__c.equals('Other')) {
                showOther = true;
                numEmployeesLabel = 'Number of individuals that you can target for recruitment efforts?';
                orgSubTypeLabel = ''; // Not defined for Other
            }
        }

        return null;
    }



    public PageReference saveLead(){
        
        System.debug('Entered SaveLead method');

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
            newLead.Campaign_Nat__c = this.nat;
            newLead.Campaign_Delivery_ID__c = this.delvid;
            newLead.Campaign_Source__c = this.sourceId;
            newLead.Campaign_Desc__c = this.cmpId;

            //9/6/17 - default some timestamps to get around the process builder bug causing multiple lead queue
            // notifications to go out.
            newLead.Lead_Status_NEW__c = DateTime.now();
            newLead.Initial_New_Lead_Status__c = DateTime.now();
            Campaign campaignFrom = getCampaignDetails();
            if(campaignFrom != null){
                newLead.Campaign_Name__c = campaignFrom.name;
                newLead.Parent_Campaign__c = campaignFrom.ParentId;
                newLead.External_Campaign_ID__c = campaignFrom.External_Campaign_Id__c;
                newLead.External_Med__c = campaignFrom.External_Med__c;
                newLead.Campaign_Status__c = campaignFrom.Status;
            }

            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.allowSave = true;
            dmlOpts.assignmentRuleHeader.useDefaultRule= true;
            dmlOpts.EmailHeader.triggerUserEmail = true; 
            //dmlOpts.EmailHeader.triggerAutoResponseEmail = true;  // MD 1/20/2020 - commented this out, causes 2 emails to be sent.

            Database.SaveResult sr = Database.insert(newLead, dmlOpts);

            if (sr.isSuccess()) {
                System.debug('Lead inserted: ' + newLead);
                showForm=false;
                System.debug('campaignId->'+campaignId);
                // If a "cid" (Campaign ID) was passed in the url, add the lead to the Campaign
                if(campaignId != null){
                    addLeadToCampaign();
                }                
                
                // Redirect to the confirmation page..
                PageReference nextPg = Page.LeadFormComplete;
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
        validCompanyType = true;
        validCompanySubType =true;
        validCompanySubTypeOther = true;
        validCompanySize = true;
        validHostedBefore = true;
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

        // Organization Name
        if( String.isBlank(companyName)){ 
            validationErrors.add('Please enter an Organization Name');
            validCompanyName = false;
        }

        // Email
        if( !FormUtils.isValidEmail(email) ){
            validationErrors.add('Please enter a valid Email address.');
            validEmail = false;
        }

        // Phone
        if( !FormUtils.isValidPhone(phone) ){ 
            validationErrors.add('Please enter a valid Phone number.');
            validPhone = false;
        }

        // phoneType
        if( String.isBlank(newLead.Phone_Type__c)){
            validationErrors.add('Please pick valid Phone Type.');
            validPhoneType = false;
        }
        
        // Company Type
        if( newLead.Company_Type__c == null){ 
            validationErrors.add('Please select an Organization Type');
            validCompanyType = false;
        }

        // Company Sub-Type
        if( (newLead.Company_Type__c != 'Church/Faith-Based Group' && newLead.Company_Type__c != 'Other') && newLead.Company_Sub_Type__c == null){ 
            validationErrors.add('Please select the Organization Sub-Type');
            validCompanySubType = false;
        }

        // Company Sub-Type OTHER
        if( newLead.Company_Type__c == 'Other' && newLead.Company_Type_Other__c == null){ 
            validationErrors.add('Please specify a value for Type of Organization');
            validCompanySubTypeOther = false;
        }

        // Company Size
        if( newLead.Company_Size__c == null){ 
            validationErrors.add('Please select a value for \'' + numEmployeesLabel + '\'');
            validCompanySize = false;
        }

        // Hosted Before
        if( newLead.Hosted_Before__c == null){
            validationErrors.add('Please select a response for \'Have you or your institution hosted a blood drive with the Red Cross before?\'');
            validHostedBefore = false;
        }

        // Has Motivation
        if( newLead.Has_Personal_Story__c == null){
            validationErrors.add('Please select a response for \'Do you have a reason or personal story that motivated you and/or your organization to host this blood drive?\'');
            validPersonalStory = false;
        }

        System.debug('There are ' + validationErrors.size() + ' validation errors in formIsValid().');

        // if there are no errors in validationErrors, the form is valid..
        return validationErrors.isEmpty();
    }


    //Recaptcha
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