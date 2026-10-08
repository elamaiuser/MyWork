/*@Description: This controller works for Publicity Order Report
  @Modification Log 
 * 
 * Date					Developer Name			Comments
 *****************************************************************************************************************************************************************************
 26-09-2023				Kishore Das				Logic for HRP-11051(GEO_Publicity Report Not Functioning)
 03/18/24               Venkat D 				Logic for HRP-12165(Publicity Ordering Report Missing District/Recruitment Team Selection)
 09/25/26               Debabrata				Logic for HRP-18010(Added Print Appt Contact, Local Offerings, Package and Theme to the report)
 *****************************************************************************************************************************************************************************
*/

public class PublicityReportNewPortfoliosController {


	//String searchRegion;
    public String searchPortfolio{get; set;}
    
    Date driveStartDate;
	Date driveEndDate;
	Date orderApprovedDate1;
	Date orderApprovedDate2;
    
    
    public List<SelectOption> portfolioOptions {
        get{List<SelectOption> options = new List<SelectOption>();
 	 	List<Bsf_Portfolio__c> bsfportfolio = [select Name from Bsf_Portfolio__c where ((Taxonomy_Type__c=:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE) OR (Taxonomy_Type__c=:BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)) And((Portfolio_Type__c='Account Manager') OR (Portfolio_Type__c='District Manager'))
                AND Start_date__c >= 2024-01-22 order by Name]; //Logic for HRP-11051

        List<String> portfoliNames = new List<String>();
        portfoliNames.add('None');
        for (Bsf_Portfolio__c bsf : bsfportfolio)
        {
            If(!portfoliNames.contains(bsf.Name))
            {
             portfoliNames.add(bsf.Name);
            }
        }
            
            
        for (String bsf : portfoliNames)
        {
            options.add(new SelectOption(bsf,bsf));
        }
 	 	return options;
           }
        set{}
  	}
    
   Public PublicityReportNewPortfoliosController()
	{
		driveStartDate = system.today();
		driveEndDate   = system.today().addMonths(6);
        orderApprovedDate1 = system.today().addDays(-8);
        orderApprovedDate2 = system.today();
        errorPresent=false;
        ReportDataWrapperListPresent=false;
    }
       
    public class ReportDataWrapper
    {
		
		public OrderItem oitem {get;set;}
        public Opportunity opp {get; set;}
        public OpportunityContactRole ocr {get;set;}
        public OpportunityContactRole printApptOcr {get;set;} //HRP-18010
        public Opportunity_Promotion__c optypro {get;set;}
        public Boolean isSelected{get; set;}
        public String ufid {get; set;}
        
        public String itemId {get; set;} 
        public String publishToCallCenter {get; set;}
      	public String webScheduling {get; set;}       
        
        public ReportDataWrapper(OrderItem oi, Opportunity op, OpportunityContactRole ocon,Opportunity_Promotion__c opptypro,String extId,String itemIdWrapL,List<String> checkboxItems)
        {   
		    oitem = oi;
		    opp = op;
            ocr = ocon;
            optypro = opptypro;
            isSelected = false;
            ufid = extId;
                        
            itemId = itemIdWrapL;
            publishToCallCenter = checkboxItems[0];
            webScheduling = checkboxItems[1];            
        }
    }
    
     public class ReportQueryWrapper
     {
        public Opportunity oppWrap {get; set;}
        Account acc;
        public String checkboxWrap {get; set;}
        public OpportunityContactRole ocrWrap {get;set;}
        public OpportunityContactRole printApptOcrWrap {get;set;} //HRP-18010
        public OrderItem oitemWrap {get;set;}
        public Opportunity_Promotion__c optyproWrap {get;set;}
        public String ufid {get;set;}
        public String driveDate {get;set;}
        public String startTime {get;set;}
        public String endTime {get;set;}
        public String publishToCallcentre{get;set;}
        public String webSchedulingEnabled {get;set;}
        public String itemIdWrapExcel {get;set;} 
        
    }
        
    public List<ReportDataWrapper> ReportDataWrapperList {get; set;}
    public list<ReportQueryWrapper> ReportQueryWrapperList {get; set;}
    public String errorMsg {get; set;}
    public String newLine {get; set;}
    public boolean errorPresent{get; set;}
    public boolean ReportDataWrapperListPresent{get; set;}
    public String clear {get; set;}
    set<id> oppIdSet = new set<id>();
	set<id> orderIdSet = new set<id>();
	set<id> orderItemIdSet = new set<id>();
	set<String> accNameSet = new set<String>();
    set<String> accIdSet = new set<String>();     
    public map<id,id> ordItemOppIdMap = new map<id,id>();
    public map<id,OpportunityContactRole> ocrMapOpp = new map<id,OpportunityContactRole>();
    public map<id,OpportunityContactRole> printApptOcrMapOpp = new map<id,OpportunityContactRole>(); //HRP-18010
	public map<id,Opportunity> OppMap = new map<id,Opportunity>();
	public map<id,Opportunity_Promotion__c> oppPromotionMap = new  map<id,Opportunity_Promotion__c>();
    public map<id,String> ufidMap = new  map<id,String>();
    
    public map<string,String> concatenatedItemIdMap = new map<string,String>(); 
    
	
	public Date getDriveStartDate(){return driveStartDate;}
    public void setDriveStartDate(Date userinp){this.driveStartDate=userinp;}
	
	public Date getDriveEndDate(){return driveEndDate;}
    public void setDriveEndDate(Date userinp){this.driveEndDate=userinp;}
	
	public Date getorderApprovedDate1(){return orderApprovedDate1;}
    public void setorderApprovedDate1(Date userinp){this.orderApprovedDate1=userinp;}
	
	public Date getorderApprovedDate2(){return orderApprovedDate2;}
    public void setorderApprovedDate2(Date userinp){this.orderApprovedDate2=userinp;}
    
    
        
    public void search()
	{ 
        ReportDataWrapperList=null;
        String whereCondition = null;
        List<String> queryConditions = new List<String>();
        
        oppIdSet.clear();
        orderIdSet.clear();
        orderItemIdSet.clear();
        accNameSet.clear();
        accIdSet.clear();
        concatenatedItemIdMap.clear(); 
        
        if((String.isBlank(searchPortfolio)|| searchPortfolio=='None') && driveStartDate == null && driveEndDate == null 
           	&& orderApprovedDate1 == null && orderApprovedDate2 == null ){
               errorMsg = 'No Input Found';
                errorPresent =true;
        }
        
        if(String.isNotBlank(searchPortfolio) && !searchPortfolio.equalsIgnoreCase('None')){
            //Logic for HRP-12165
            /*
			for(Account_Portfolio_Assignment__c accPort: [SELECT Id, Account__r.Name, Account__c 
                FROM Account_Portfolio_Assignment__c 
                WHERE (BSF_Portfolio__r.Name=:String.escapeSingleQuotes(searchPortfolio) AND 
                        BSF_Portfolio__r.Portfolio_Type__c=:BSF_Constants.ACCOUNT_MANAGER) 
                OR (BSF_Portfolio__r.Parent_Portfolio__r.Name=:String.escapeSingleQuotes(searchPortfolio) AND 
                    BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c=:BSF_Constants.DISTRICT_MANAGER) 
                OR (BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Name=:String.escapeSingleQuotes(searchPortfolio) AND 
                    BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c=:BSF_Constants.DISTRICT_MANAGER)]){

        		accNameSet.add(accPort.Account__r.Name); 
                accIdSet.add(accPort.Account__c);      
            }*/
            
            queryConditions.add(
                '(order.Opportunity.Account_Manager_Portfolio__r.Name = :searchPortfolio OR ' +
                'order.Opportunity.District_Manager_Portfolio__r.Name = :searchPortfolio)'
            );
        }
        /*
        if(accIdSet.size() > 0){
             queryConditions.add('order.opportunity.accountId in :accIdSet');
        }*/
        
        
        if(driveStartDate != null){
			queryConditions.add('Order.Opportunity.Drive_Date__c >= :driveStartDate');            
        }
        if(driveEndDate != null){
			queryConditions.add('Order.Opportunity.Drive_Date__c <= :driveEndDate');            
        }
        if(orderApprovedDate1 != null){
			queryConditions.add('order.Publicity_Approved_Date__c >= :orderApprovedDate1');            
        }
        if(orderApprovedDate2 != null){
			queryConditions.add('order.Publicity_Approved_Date__c <= :orderApprovedDate2');            
        }
        	
        if(queryConditions.size() > 0){
            whereCondition = ' WHERE ' +String.join(queryConditions, ' AND ');
        }
        
        system.debug('whereCondition ' + whereCondition);
        
        if(whereCondition != null){
            errorMsg = null;
           
            List<OrderItem> opprodList = getQueryResult(whereCondition);
            for(OrderItem ordItem:opprodList){
                oppIdSet.add(ordItem.order.OpportunityId);
            }
            list<OpportunityContactRole> ocrlist = [Select Contact.Firstname,Contact.Lastname,Contact.Name,contact.Mobilephone,
                contact.individual.Name,contact.HomePhone,Role,Opportunityid,contact.OtherStreet,contact.OtherCity,Contact.OtherState,
                Contact.OtherPostalCode,contact.OtherCountry,contact.Primary_Phone_Number_New__c,contact.Email 
                from OpportunityContactRole where OpportunityId in :oppIdSet and role= 'Publicity Materials Recipient' ];
            //HRP-18010: newest first, so the first role found per Opportunity is the latest assigned Print Appt Contact
            printApptOcrMapOpp.clear();
            for(OpportunityContactRole printApptOcr : [Select ContactId,Contact.Name,contact.Primary_Phone_Number_New__c,Opportunityid
                from OpportunityContactRole where OpportunityId in :oppIdSet and role= 'Print Appt Contact' order by CreatedDate desc, Id desc]){
                if(!printApptOcrMapOpp.containsKey(printApptOcr.OpportunityId)){
                    printApptOcrMapOpp.put(printApptOcr.OpportunityId, printApptOcr);
                }
            }
            list<Opportunity_Promotion__c> oppPromotionList = [select Promotion__r.Name,Promotion__c,Blood_Drive_Opportunity__c 
                from Opportunity_Promotion__c where Blood_Drive_Opportunity__c in :oppIdSet];
            list<Opportunity> oppList = [select id,Drive_Name__c,AccountId,Account.Name,End_Time__c,Direct_Donors_To__c,Drive_Date__c,
                Open_to_Public__c,Total_Projected_Procedures__c,
				Start_Time__c,Call_List_Recipient_Exist__c,Drive_Site_Name__c,Drive_Site__r.sked__Address__c,Drive_Site__r.sked_Address_1__c,
				Drive_Site__r.sked_City__c,Drive_Site__r.sked_State__c,Drive_Site__r.sked_Zip_Code__c,
				Drive_Keyword__c,Related_Scheduled_Drive__r.sked_Drive_External_Id__c,Related_Scheduled_Drive__r.Sked_UFID__c,Account_Manager__c,Account_Manager__r.Name,Total_Products_Projected__c,
				Online_Scheduling_Enabled__c,Collections_Zip_Code__r.Collection_Operation__r.sked_Start_Time_Offset__c,Collections_Zip_Code__r.Collection_Operation__r.sked_End_Time_Offset__c,
                Publish_to_Call_Center__c, Web_Scheduling_Enabled__c from Opportunity where id in :oppIdSet];
            List<sked_Drive__c> drvList = [SELECT Id,
                                                 sked_Opportunity__c,
                                                 sked_UFID__c
                                                FROM sked_Drive__c 
                                                WHERE sked_Opportunity__c IN: oppIdSet];
            bindWithWrapperClass(opprodList,oppList,ocrlist,oppPromotionList,drvList); 
        }
	}
     
    List<OrderItem> getQueryResult(String condition)
	{
        list<OrderItem> opprodList = new list<OrderItem>();
       
        string q  = 'select id,order.OpportunityId,order.Opportunity.Drive_Status__c,orderId,order.BudgetCurrency__c,order.Publicity_Comment__c,Material_Recipient__c,'+
                    'order.Local_Offerings__c,order.AdditionalComments__c,order.Publicity_Package__r.Name,order.Theme__r.Name,'+ //HRP-18010
                    'order.OrderNumber,order.Publicity_Approved_By__r.Name,order.Material_Recipient__c,order.id,Product2.Name,Product2.PRODUCT_ID__C,Quantity,order.Publicity_Approved_By__c,order.Publicity_Approved_Date__c from orderItem '+
                     condition+' and order.Publicity_Submitted__c = false and order.Publicity_Approved__c = true '+
                     'AND order.OpportunityId != null AND order.Opportunity.Drive_Status__c != \'Cancel\' '+ //Added for HRP-9324
                     'ORDER BY order.OrderNumber DESC NULLS LAST LIMIT 500';
        
        opprodList = Database.query(q);
        return opprodList;
    }
    
    public void bindWithWrapperClass(list<OrderItem> opprodList,
                                    List<Opportunity>oppList,
                                    List<OpportunityContactRole>ocrlist,
                                    List<Opportunity_Promotion__c>oppPromotionList,
                                    List<sked_Drive__c> drvList){
       	reportDataWrapperList = new List<ReportDataWrapper>();
        
        String publishToCallCenter = ''; 
        String webSchedulingEnabled = ''; 
        String itemIdWrap;        
        concatenatedItemIdMap = getConcatenatedItemIdForSizeProducts(opprodList); 
        
	   	for(OrderItem ordItem:opprodList)
		{
			ordItemOppIdMap.put(orditem.id,ordItem.order.opportunityId);
		}
        for(Opportunity opp:oppList)
		{
			OppMap.put(opp.ID,opp);
		}
		
        for(OpportunityContactRole ocr:ocrlist)
		{
			ocrMapOpp.put(ocr.opportunityId,ocr);
		}
		
        for(Opportunity_Promotion__c oppPr:oppPromotionList)
		{
			oppPromotionMap.put(oppPr.Blood_Drive_Opportunity__c,oppPr);
		}
        for(sked_Drive__c drv : drvList){
          ufidMap.put(drv.sked_Opportunity__c,drv.sked_UFID__c);
        }
           
        for(OrderItem OrdItem: opprodList) 
		{
            String concatenatedItemId = concatenatedItemIdMap.get(ordItem.OrderId+'_'+ordItem.Product2.product_Id__c);
            itemIdWrap = concatenatedItemId != null ? concatenatedItemId : ordItem.Product2.Product_Id__c;
            
            id oppId = ordItemOppIdMap.get(OrdItem.id);
            
            opportunity opp = OppMap.get(ordItemOppIdMap.get(OrdItem.id));
            
            if(opp.Publish_to_Call_Center__c)
            {
                publishToCallCenter = 'X';
            }
            
            if(opp.Web_Scheduling_Enabled__c)
            {
                webSchedulingEnabled = 'X';
            }
            List<String> checkboxItems = new List<string>{publishToCallCenter,webSchedulingEnabled};
                
            
            opportunityContactRole ocr = ocrMapOpp.get(oppId);
            Opportunity_Promotion__c orPromo = oppPromotionMap.get(oppId);
            String extid = ufidMap.get(oppId);
           
            if(opp == null){
                opp = new opportunity();
            }
            if(ocr == null){
                ocr = new opportunityContactRole();
            }
            if(orPromo == null){
                orPromo = new Opportunity_Promotion__c();
            }
            
            //HRP-18010: Specify Local Item Offered is shown only when a Local Offering is selected on the Order
            if(String.isBlank(OrdItem.Order.Local_Offerings__c)){
                OrdItem.Order.AdditionalComments__c = null;
            }

            ReportDataWrapper dataWrapper = new ReportDataWrapper(OrdItem,opp,ocr,orPromo,extid,itemIdWrap,checkboxItems);
            dataWrapper.printApptOcr = printApptOcrMapOpp.containsKey(oppId) ? printApptOcrMapOpp.get(oppId) : new opportunityContactRole(); //HRP-18010
            reportDataWrapperList.add(dataWrapper);
       	}
         if(!reportDataWrapperList.isEmpty())
         {ReportDataWrapperListPresent=true;}
        system.debug('ReportDataWrapperList ' + reportDataWrapperList);
    }
    
    public void selectedRecords(){       
        ReportQueryWrapperList = new  list<ReportQueryWrapper>();  
        list<OrderItem>  selectedOrdItemList = new list<OrderItem>();
        map<Id,String> callListMap = new map<Id,String>();
                
        String callListRecipient ='No';
        String publishCallCentre = ''; 
        String webSchedulingEnabled = ''; 
        String concateNatedItemId; 
        Map<Id,List<String>> wrapDataMap = new Map<Id,List<string>>();
        
        if(ReportDataWrapperList != null)
        {
            for(ReportDataWrapper wrapData : ReportDataWrapperList)
            {                        
                if(wrapData.isSelected == true)
                {
                    selectedOrdItemList.add(wrapData.oitem);
                    if (wrapData.opp.Call_List_Recipient_Exist__c==true)
                    {
                        callListRecipient = 'Yes';
                        callListMap.put(wrapData.opp.Id,callListRecipient);
                    }
                    else{callListMap.put(wrapData.opp.Id,callListRecipient);}
                    
                    publishCallCentre = wrapData.publishToCallCenter; 
                    webSchedulingEnabled = wrapData.webScheduling; 
                    concateNatedItemId = wrapData.itemId;
                    wrapDataMap.put(wrapData.oitem.Id, new List<String>{publishCallCentre,webSchedulingEnabled,concateNatedItemId});
                    
                }      
            }  
        }
        
        for(orderItem ordItem: selectedOrdItemList){
            id oppId = ordItemOppIdMap.get(OrdItem.id);
            ReportQueryWrapper ReportQueryWrapperObj = new ReportQueryWrapper();
            ReportQueryWrapperObj.oppWrap = OppMap.get(oppId); 
            ReportQueryWrapperObj.checkboxWrap=callListMap.get(oppId);
            ReportQueryWrapperObj.ocrWrap = ocrMapOpp.get(oppId);
            ReportQueryWrapperObj.printApptOcrWrap = printApptOcrMapOpp.get(oppId); //HRP-18010
            ReportQueryWrapperObj.oitemWrap = ordItem;
            ReportQueryWrapperObj.optyproWrap = oppPromotionMap.get(oppId);
            ReportQueryWrapperObj.ufid = ufidMap.get(oppId);
            ReportQueryWrapperObj.driveDate = formatDate(OppMap.get(oppId).Drive_Date__c);
            ReportQueryWrapperObj.startTime = getFormattedTime(OppMap.get(oppId).Start_Time__c.hour(),OppMap.get(oppId).Start_Time__c.minute());
            ReportQueryWrapperObj.endTime = getFormattedTime(OppMap.get(oppId).End_Time__c.hour(),OppMap.get(oppId).End_Time__c.minute());
           
            ReportQueryWrapperObj.itemIdWrapExcel = wrapDataMap.get(ordItem.Id)[2];
            ReportQueryWrapperObj.publishToCallcentre = wrapDataMap.get(ordItem.Id)[0];
            ReportQueryWrapperObj.webSchedulingEnabled = wrapDataMap.get(ordItem.Id)[1];
            
            ReportQueryWrapperList.add(ReportQueryWrapperObj);
            system.debug('ReportQueryWrapperList '+ ReportQueryWrapperList);    
        }
    }
    public PageReference ExportToExcel() {
        selectedRecords();
        
        return Page.publicityReportExcel1; //Changes for HRP-11051
    }
    public PageReference ExportToCSV() {
        newLine = '\n';
        selectedRecords();        
        return Page.PublicityReportCSV1;//Changes for HRP-11051
    }
    
    
    public void clear(){
         
        ReportDataWrapperList = null;
       	searchPortfolio='None';
        driveStartDate=null;
        driveEndDate=null;
        orderApprovedDate1=null;
		orderApprovedDate2=null;
        errorPresent=false;
        ReportDataWrapperListPresent=false;
        system.debug('clear '+ ReportDataWrapperList);
         
    }
    public String formatDate(date preDate){
        String result = '';
        if(preDate != null){
            DateTime dDate = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day());
            result = dDate.format('M/d/yyyy');
        }
        return result;
    }
    public DateTime getUserLocalTime(Datetime dt){
        Timezone tz = UserInfo.getTimeZone();
        Integer offset = tz.getOffset(system.now());
        Datetime cstDatetime = System.now().addSeconds(offset/1000);
        return cstDatetime;
    }
    public String getFormattedTime(Integer hour, Integer minutes){
        System.debug('inputs hour--> '+hour);
        System.debug('inputs minutes--> '+minutes);
        String st;
        if(hour == 0){
            hour = 12;
            st = ' AM';
        }else if(hour < 12){
            st = ' AM';
        }else if(hour == 12){
            st = ' PM';
        }else if(hour > 12){
            hour = hour - 12;
            st = ' PM';
        }
        if(minutes < 10){
            System.debug('final --> '+hour+':0'+minutes+st);
            return hour+':0'+minutes+st;
        }else{
            System.debug('final --> '+hour+':'+minutes+st);
            return hour+':'+minutes+st;
        }
    }
    
    
    public static Map<String,String> getConcatenatedItemIdForSizeProducts(List<OrderItem> orderItemList)
    {
      	Map<String,String> concatenatedItemIdMap = new Map<String,String>();
       	Map<Id, set<String>> orderIdToSizeProductmap = new Map<Id, set<String>>();
        Map<Id,String> orderIdtoThemeProductMap = new Map<Id,String>();
        String patternMatchForSizeProducts = 'Size -';

		for (OrderItem ordItem : orderItemList)
    	{
            String productName = ordItem.Product2.Name;
            String productItemId = ordItem.Product2.Product_Id__c;
    		Id orderId = ordItem.OrderId;
            
            if(String.isNotBlank(productName) && String.isNotBlank(productItemId))
            {	   
                if (productName.startsWithIgnoreCase(patternMatchForSizeProducts) && !productItemId.containsIgnoreCase('theme'))
                {
                    if (!orderIdToSizeProductmap.containsKey(orderId))
                    {
                        orderIdToSizeProductmap.put(orderId, new Set<String>());
                    }
                    orderIdToSizeProductmap.get(orderId).add(productItemId);
                }
                else if(productName.containsIgnoreCase('theme') && !productItemId.containsIgnoreCase('size'))
                {
                    if (!orderIdtoThemeProductMap.containsKey(orderId))
                    {
                        orderIdtoThemeProductMap.put(orderId, productItemId);
                    }
                }
            }
        }
        
        if(!orderIdToSizeProductmap.isEmpty())
        {
            for(Id ids: orderIdToSizeProductmap.keySet())
            {
                for(String str: orderIdToSizeProductmap.get(ids)) 
                {
                	if(orderIdtoThemeProductMap.get(ids)!=null)
                	{                                                
                       concatenatedItemIdMap.put(ids+'_'+str,orderIdtoThemeProductMap.get(ids)+'.'+str);                       
                    }
                else{
                    concatenatedItemIdMap.put(ids+'_'+str,str);                    
                }
               }
            }
        }
        
      	return concatenatedItemIdMap;
    }
    
}