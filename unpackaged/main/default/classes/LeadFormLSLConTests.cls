@isTest
public class LeadFormLSLConTests {
    
    @testSetup
    static void setup(){
        
        Collections_Region__c testRegion = new Collections_Region__c(Name = 'Test Region');
        insert(testRegion);

        Collections_Territory__c goodTerritory = new Collections_Territory__c(
            Zip__c = '02770', 
            City__c = 'Rochester',
            State_Code__c = 'MA',
            Service_Area__c = true,
            Region__c = testRegion.Id
        );
        insert(goodTerritory);



        Collections_Territory__c badTerritory = new Collections_Territory__c(
            Zip__c = '27587', 
            City__c = 'Wake Forest',
            State_Code__c = 'NC',
            Service_Area__c = false,
            Region__c = testRegion.Id
        );
        insert(badTerritory);
        
         Collections_Territory__c badTerritory2 = new Collections_Territory__c(
            Zip__c = '20105', 
            City__c = 'Aldie',
            State_Code__c = 'NC',
            Service_Area__c = false,
            Region__c = testRegion.Id
        );
        insert(badTerritory2);
        
        Date startDate = system.today().addDays(30);
        Date endDate = system.today().addDays(-30);
        
        String taxonomyBioSFRecordType = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_COLLECTION_RECORD_TYPE).getRecordTypeId();

        Taxonomy__c taxonomy = new Taxonomy__c(ABM_Code__c='GEOR_S Georgia Coastal_ABM', ABM_Key__c=115960, ABM_Name__c='Georgia Coastal ABM', Division_Code__c='BD33', Division_Key__c=42263, Division_Name__c='Southeast and Caribbean', DRD_Territory_Code__c='HProdSED_755', DRD_Territory_Key__c=115893, DRD_Territory_Name__c='GA South 02', DS_Region_Code__c='03E', DS_Region_Key__c=42058, DS_Region_Name__c='Georgia', End_Date__c=System.today()+180, RecordTypeId=taxonomyBioSFRecordType,Start_Date__c=System.today()-10,Team_Code__c='GEOR_S Georgia Coastal', Team_Key__c=42878, Team_Name__c='GEOR_S Georgia Coastal', Time_Zone__c='America/New_York', Type_Key__c=169, Type__c=BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE, Zip_Code_Key__c=20105, Zip_Code__c='20105', Zip_Code_Name__c='20105',Version_Key__c=1000,City__c='Aldie',State__c='VA');

        //Taxonomy__c taxonomy = new Taxonomy__c(Zip_Code__c='20105',Start_Date__c=startDate,End_Date__c=endDate,City__c = 'Wake Forest',State__c = 'NC');
        insert taxonomy;
    }

    
    
    
    static testMethod void pageLoadTest() {
        // Make sure certain properties are set when a page loads
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);
        

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con;

        Test.startTest();
            con = new LeadFormLSLCon();
        Test.stopTest();

        // Test: did the controller create a new Lead object?
        System.assert(con.newLead != null);

    }
    
     static testMethod void formValid1() {
        // Make sure certain properties are set when a page loads
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        
        
        con.firstName = '';
        con.lastName = '';
        con.companyName = '';
        con.email = '';
        con.phone = '';
        con.newLead.Company_Type__c = null;
        //con.setCompanyType();   

        Test.startTest();
         
            con.formIsValid();
            
        Test.stopTest();

        // Test: did the controller create a new Lead object?
        System.assert(con.newLead != null);
        System.assertEquals(false, con.validFirstName);
        System.assertEquals(false, con.validLastName);
        System.assertEquals(false, con.validCompanyName);
        System.assertEquals(false, con.validEmail);
        System.assertEquals(false, con.validPhone);
    }
    
    
    
     
    
    
  
    static testMethod void stateOpts() {
        
        // Validates that the Lead Form's State picklist has some options 
        // 
        
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        List<SelectOption> opts = new List<SelectOption>();
        
        Test.startTest();
           con.getStateOpts();
        Test.stopTest();
        
        System.assertEquals(0,opts.size());
    }
    
    
    static testMethod void validZipTest() {

        // A valid zip code results in the form being displayed
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = true];
        

        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        //con.did = '';
        Lead l = con.newLead;
        l.PostalCode = t.Zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        l.Company_Type__c = 'Church/Faith-Based Group';


        Test.startTest();
            con.validateZipcode();
            //con.setCompanyType();
        Test.stopTest();

		//Update 12024- we are removing territory dependency and moved to taxonomy completely
        System.assertEquals(null,con.territory); 
        //System.assertEquals(true, con.showRel); // because the Company_Type__c = 'Church/Faith-Based Group', the "showRel" property should be true

    }

    static testMethod void invalidZipTest(){
        // A bad zip code results in an error

        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        //con.did = '';
        Lead l = con.newLead;
        l.PostalCode = 'FRANK'; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        Test.startTest();
            con.validateZipcode();
        Test.stopTest();


        System.assertEquals(false, con.areaServed);
        System.assertEquals(false, con.validZip);
        System.assertEquals(null,con.territory);    
        
    }

    static testMethod void unknownZipTest(){
        // if the zip code isn't in the Collections Region table, we still want to show 
        // the lead form and capture their information

        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        //con.did = '';
        Lead l = con.newLead;
        l.PostalCode = '99999'; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        Test.startTest();
            con.validateZipcode();
        Test.stopTest();


        System.assertEquals(false, con.areaServed);
        System.assertEquals(false, con.validZip);
        System.assertEquals(null,con.territory);
    }


    static testMethod void nonServiceZipTest(){
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false and Zip__c = '27587' limit 1];
        List<Taxonomy__c> taxonomyList =[select id, Zip_Code__c from Taxonomy__c where Zip_code__c = '27587'];

        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadForm;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        
        con.did = '';

        Test.startTest();
            con.validateZipcode();
        Test.stopTest();


        System.assertEquals(false, con.areaServed);//this will be false, on lack of taxonomy record 
        System.assert(taxonomyList.size() == 0);
        
    }

    static testMethod void nonServiceZipTestWithValidTaxonomy(){
        // if the zip code isn't in the ARC blood collections service area, we want to stop the user from seeing the form and wasting their time.

        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false and Zip__c = '20105' limit 1];
        Taxonomy__c taxonomy =[select id, Zip_Code__c from Taxonomy__c where Zip_Code__c = '20105' limit 1];
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadForm;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        
        con.did = '';

        Test.startTest();
            con.validateZipcode();
        Test.stopTest();


        System.assertEquals(true, con.areaServed);//this will be true, because of presence of taxonomy record
        System.Assert(taxonomy != null);
        System.assertEquals(true, con.validZip);
        
    }

    static testMethod void invalidFormTest(){

        // If an invalid phone and/or email is provided, the lead record will not be saved and
        // validation messages will be presented to the user
        
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        //con.did = '';
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        l.Company_Type__c = 'Business';
        //con.setCompanyType();
        
        l.Company_Sub_Type__c = 'Corporation';
        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        l.Company_Size__c = '501 - 1000';
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.title = 'President';
        con.email = 'test@here.org.test'; // Important for this test: an invalid email
        con.phone = '888-7878'; // Important for this test: an invalid phone format
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Testinghouse Inc.';


        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertNotEquals(null, con.validationErrors);
        

    }



    static testMethod void leadSaveTest(){

        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadForm;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormCon con = new LeadFormCon();
        //con.did = '';
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        l.Company_Type__c = 'Education';
        con.setCompanyType();
        l.Company_Type__c = 'Civic/Community';
        con.setCompanyType();
        l.Company_Type__c = 'Media Outlet';
        con.setCompanyType();
        l.Company_Type__c = 'Healthcare';
        con.setCompanyType();
        l.Company_Type__c = 'Military/Government/NGO';
        con.setCompanyType();
        l.Company_Type__c = 'Other';
        con.setCompanyType();
        l.Company_Type__c = 'Business';
        con.setCompanyType();
        
        l.Company_Sub_Type__c = 'Corporation';
        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        l.Company_Size__c = '501 - 1000';
        l.Phone_Type__c = 'Mobile phone';
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.title = 'President';
        con.email = 'test@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Testinghouse Inc.';


        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size());

        Lead[] leadResult = [select id, Collections_Territory__c from Lead where Email = :con.email];
        System.assertNotEquals(null, leadResult[0]);
        //System.assertEquals(t.Id, leadResult[0].Collections_Territory__c);

    }
    
    
        
        
    static testMethod void LslSaveTest(){

        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);

        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        //con.did = '';
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.email = 'test.lsl.lead@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Test High School';
        l.Age_Group__c = '16 - 18';
        l.Current_Blood_Donor__c = 'No';
        l.Student_Type__c = 'High School';
        l.Phone_Type__c = 'Mobile phone';
        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size(), con.validationErrors);

        Lead[] leadResult = [select id, Company_Type__c, RecordType.Name, Collections_Territory__c from Lead where Email = :con.email];
        //System.assertNotEquals(null, leadResult);
        //System.assertEquals(t.Id, leadResult.Collections_Zipcode__c);
        //System.assertEquals('Education', leadResult.Company_Type__c);
        System.assertEquals('LSL', leadResult[0].RecordType.Name);

    }
    
    
    static testMethod void validCampaignIdTest(){
        
        // A valid campaignId is passed in the url/querystring
        
        final string DID_VAL = 'LSL_4848484';
        
        Campaign testCampaign = new Campaign(
            Name = 'Test LSL Campaign', 
            IsActive = true, 
            External_Campaign_Id__c = 'ABC123',
            External_Cid__c='cid123',
            External_Med__c='med123',	
            External_Source__c='source123',
        	External_Did__c = DID_VAL
        );
        insert(testCampaign);
        
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);


		
        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();


        // Critical for this test
        /*con.cmpId = testCampaign.External_Campaign_Id__c; // normally the ext campaign id will be passed into the form via javascript, but this will have to do.
        con.cidId = testCampaign.External_Cid__c;
        con.medId = testCampaign.External_Med__c;
        con.sourceId = testCampaign.External_Source__c;*/
        //con.did = DID_VAL;
        con.validateZipcode();


        
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.email = 'test.lsl.lead@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Test High School';
        l.Age_Group__c = '16 - 18';
        l.Current_Blood_Donor__c = 'No';
        l.Student_Type__c = 'High School';
	    l.Phone_Type__c = 'Mobile phone';
        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size(), con.validationErrors);

        Lead[] leadResult = [select id, Company_Type__c, RecordType.Name, Collections_Territory__c from Lead where Email = :con.email];
        
    	// Verify a CampaignMember record was created.
        //CampaignMember cmTest = [select Id, LeadId from CampaignMember where CampaignId = :testCampaign.Id];
        //System.assertEquals(cmTest.LeadId, leadResult.Id);
    
    }
    
    static testMethod void invalidCampaignIdTest(){
        
        // An INvalid campaignId is passed in the url/querystring
        
        
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadFormLSL;
        Test.setCurrentPage(leadFormPgRef);
		ApexPages.currentPage().getParameters().put('cid','bogus_campaign_id'); // IMPORTANT FOR THIS TEST
        
        // Create an instance of our page's controller for testing
        LeadFormLSLCon con = new LeadFormLSLCon();
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.
        

        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.email = 'test.lsl.lead@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Test High School';
        l.Age_Group__c = '16 - 18';
        l.Current_Blood_Donor__c = 'No';
        l.Student_Type__c = 'High School';
        l.Phone_Type__c = 'Mobile phone';
        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size(), con.validationErrors);

        
        // Verify the lead was created
        Lead[] leadResult = [select id, Company_Type__c, RecordType.Name, Collections_Territory__c from Lead where Email = :con.email];
        System.assert(leadResult[0].Id != null);
        
    	// Verify a CampaignMember record NOT was created.
        List<CampaignMember> cmResults = [select Id, LeadId from CampaignMember where LeadId = :leadResult[0].Id];
        System.assertEquals(0, cmResults.size());
    
    }
    
    /*
    static testMethod void validCampaignIdTest(){

        // A valid campaign id is passed via the url, the new lead should be added to the campaign
        // 
        
        
        Campaign testCampaign = new Campaign(Name = 'Test Campaign', IsActive = true);
        insert(testCampaign);
        
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadForm;
        Test.setCurrentPage(leadFormPgRef);
		ApexPages.currentPage().getParameters().put('cid',testCampaign.Id); // IMPORTANT FOR THIS TEST
        
        // Create an instance of our page's controller for testing
        LeadFormCon con = new LeadFormCon();
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.l.Company_Type__c = 'Education';
        l.Company_Type__c = 'Business';
        con.setCompanyType();
        
        l.Company_Sub_Type__c = 'Corporation';
        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        l.Company_Size__c = '501 - 1000';
        
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.title = 'President';
        con.email = 'test@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Testinghouse Inc.';


        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size());

        Lead leadResult = [select id, Collections_Territory__c from Lead where Email = :con.email];
        System.assertNotEquals(null, leadResult);
        System.assertEquals(t.Id, leadResult.Collections_Territory__c);
        
        // Verify a CampaignMember record was created.
        CampaignMember cmTest = [select Id, LeadId from CampaignMember where CampaignId = :testCampaign.Id];
        System.assertEquals(cmTest.LeadId, leadResult.Id);

    }

    
    
    
    static testMethod void invalidCampaignIdTest(){

        // An INvalid campaign id is passed via the url, the new lead should NOT be added to a campaign
        // 
        
        
        Collections_Territory__c t = [select id, zip__c from Collections_Territory__c where Service_Area__c = false limit 1];
        
        // Set up the leadForm page for testing
        PageReference leadFormPgRef = Page.LeadForm;
        Test.setCurrentPage(leadFormPgRef);
		ApexPages.currentPage().getParameters().put('cid','bogus_campaign_id'); // IMPORTANT FOR THIS TEST
        
        // Create an instance of our page's controller for testing
        LeadFormCon con = new LeadFormCon();
        String siteKey = con.siteKey;
        System.assert(siteKey != null);
        
        Lead l = con.newLead;
        l.PostalCode = t.zip__c; // we'll use the zip code from the test Territory we created in the Setup() section so we know it exists and is valid.l.Company_Type__c = 'Education';
        l.Company_Type__c = 'Business';
        con.setCompanyType();
        
        l.Company_Sub_Type__c = 'Corporation';
        l.Hosted_Before__c = 'No';
        l.Has_Personal_Story__c = 'No';
        l.Company_Size__c = '501 - 1000';
        
        con.firstName = 'Testerly';
        con.lastName = 'Testinghouse';
        con.title = 'President';
        con.email = 'test@here.org';
        con.phone = '999-888-7878';
        con.street = '12 TEsting Way';
        con.city = 'Testingham';
        con.companyName = 'Testinghouse Inc.';


        Test.startTest();
            con.saveLead();
        Test.stopTest();

        System.assertEquals(0, con.validationErrors.size());

        Lead leadResult = [select id, Collections_Territory__c from Lead where Email = :con.email];
        System.assertNotEquals(null, leadResult);
        System.assertEquals(t.Id, leadResult.Collections_Territory__c);
        
        // Verify a CampaignMember record was created.
        List<CampaignMember> cmResults = [select Id, LeadId from CampaignMember where LeadId = :l.Id];
        System.assertEquals(0, cmResults.size());

    }
    */
}