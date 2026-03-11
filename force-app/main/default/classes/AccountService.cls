/*
* Modification Log
* Date					     Developer Name			     Comments
* *******************************************************************************************************************************************************************************************************
* 05/02/2023				  Barnojit Sharma			 Logic for HRP-9818
* 05/02/2023				  Fitsum Worku			     Logic for HRP-9880. Updated method updateNationalNameStatus to remove the hardcoded "allowed profiles" and "user to exclude" to use custom labels
* 05/03/2023				  Kishore Das				 Logic for HRP-9816 (Incorrect Address, Please Update" When Converting Leads into Accounts)
* 05/12/2023				  Balaji N				     Logic for HRP-10005 (populateMarketOnAccount, check for BillingPostalCode field Change on Update)
* 08/06/2023				  Kishore Das				 Logic for HRP-10085 (It changes all the associated opportunities/templates name when account internal name changes,also changes related drives on calendar name when account name changes.																For site, when room name/site building name changes the related opportunity/template/drives on calendar name changes)
* 06/14/2023				  Balaji N				     Logic for HRP-10099 (Method:createAccountTeamMembers, changes for HRP-10099)
* 03/08/2023				  Kishore Das		         Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
* 08/08/2023	 	  	      Balaji N				     Logic for HRP-8897 (Method:createAccountTeamMembers, datatype of Map value "accIdUserDate" and related changes)
* 09/18/2023			      Balaji N				     Logic for HRP-10878 (Method:createAccountTeamMembers,logic for duplicate removal on account portfolio assignment, new method setZipcodeChang)
* 11/09/2023		          Balaji N				     Logic for HRP-11290((Method:createAccountTeamMembers,logic for Supervisor Date check))
* 12/14/2023			      Balaji N			         Logic for HRP-6028(Method Name:createAccountTeamMembers; method call for  HandleAccountSpecialist)
* 01/04/2024                  Balaji N			         Logic for HRP-10569(Method Name:createAccountTeamMembers;parameter changes on accTeamDateSyncOnAccPortUpdates method call)
* 01/12/2024			      Priti Jana				 Logic for HRP-11418
* 02/01/2024			      Venkat & Balaji N          Logic for HRP - 12053 (Method Name:createAccountTeamMembers;Territory assignment logic correction on Zipcode change and after Exception)
* 02/13/2024		          Balaji N				     Logic for HRP-11138(Method:createAccountTeamMembers;return type account portfolio assignment list)
* 02/06/2024				  Priti Jana				 Logic for HRP-9520
* 02/26/2024			      Priti Jana				 Removed existing AuraEnabled methods to a different controller specific to HRP-11936
* 03/06/2024			      Balaji N		  	         logic for HRP-12136 (Method:getInternalNameChangedAccounts,updateDivesOnCalenderForAccountInternalNameChange;changes in opp name logic)
* 05/24/2024				  Raktim Ghosal				 Logic for HRP-12757
* 08/05/2024				  Balaji N					 Logic for HRP-12485(Method:createAccountTeamMembers;removed dependency on Account_AM_Portfolio_Type__c)
* 11/26/2024                  Balaji N                   Logic for HRP-13866 Method:createAccountTeamMembers System.Label.NO_SBPM_ABM in place of hard coded value
*********************************************************************************************************************************************************************************************************
*/
public  without sharing class AccountService {//with sharing is not needed
public static Boolean isExecuted = false;
Static boolean isMethodExecuted = false;
//AS-013046-Account Billing Address standardization, will be called from before insert and before update
public static void standardizeBillingAddress(List<Account> newAccounts, Map<Id, Account> oldMap,
Map<Id, Account> newMap, String op)
{
//System.debug('Entered method standardizeBillingAddress with oldMap and newMap' + oldMap + ' : ' + newMap);
if (System.isFuture())
{//extremely important,only run for first time otherwise will get exception future cannot be called from future
system.debug('System.isFuture()'+System.isFuture());
return;
}
//collects all leads which need to be evaluated for clean address
List<Id> evaluateAddressAccountList = new List<Id>();
for (Account newAccount:newAccounts)
{
boolean isEmptyAddress = AddressUtility.isEmptyAddress(newAccount, AddressUtility.AccountBillingAddressFieldsMap);
if (isEmptyAddress == null)
{
//System.debug('Address is null for incoming Account');
continue;
}
InformaticaStandardAddress stdAddr = null;
if (op.equals('INSERT'))
{
//System.debug('Coming in for first time insert without empty address for lead object:' + newAccount);
evaluateAddressAccountList.add(newAccount.id);//this is called from after insert, so id will be there always
}
else if (op.equals('UPDATE'))
{
//System.debug('Coming in as update');
Account oldAccount = oldMap.get(newAccount.id);
boolean isAddressChanged = AddressUtility.isAddresssChanged(oldAccount, newAccount, AddressUtility.AccountBillingAddressFieldsMap);
//System.debug('isAddressChanged:' + isAddressChanged);
if (isAddressChanged == true)
{
evaluateAddressAccountList.add(newAccount.id);//this is called from after insert/after update, so id will be there always
}
}
//Call Informatica API and clean addresses
system.debug('evaluateAddressAccountList'+evaluateAddressAccountList);
}
if(!evaluateAddressAccountList.isEmpty())
{
AddressUtility.cleanAccountBillingAddress(evaluateAddressAccountList);
}
}
/**
* AS-012769-SYSTEM: Mapping Converted Lead Fields to the Account
* */
public static void updateAccountType(List<Account> oldAccounts, List<Account> newAccounts,Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap){
// System.debug('Entered method updateAccountType');
for(Account newAccount:newAccounts){
// System.debug('Processing newAccount with account_type_from_lead__c and Id values as ->'+newAccount.account_type_from_lead__c+','+newAccount.id);
if(String.isBlank(newAccount.account_type_from_lead__c) ==true)
continue;
if(newAccount.id == null){//coming in for first time
newAccount.type=newAccount.account_type_from_lead__c;
continue;
}
if(newAccount.id != null && oldAccountsMap!=null
&& oldAccountsMap.get(newAccount.id)!=null){ //update scenario
// System.debug('Processing oldAccount with account_type_from_lead__c and Id values as ->'+oldAccountsMap.get(newAccount.id).account_type_from_lead__c+','+newAccount.id);
if(newAccount.account_type_from_lead__c != oldAccountsMap.get(newAccount.id).account_type_from_lead__c){
newAccount.type=newAccount.account_type_from_lead__c;
}
if(String.isBlank(newAccount.Type) ==true){
newAccount.type=newAccount.account_type_from_lead__c;
}
}
}//end of for loop
}
//AS-013046-Account Shipping Address standardization, will be called from before insert and before update
public static void standardizeShippingAddress(List<Account> newAccounts, Map<Id, Account> oldMap,
Map<Id, Account> newMap, String op)
{
// System.debug('Entered method standardizeShippingAddress with oldMap and newMap' + oldMap + ' : ' + newMap);
if (System.isFuture())
{//extremely important,only run for first time otherwise will get exception future cannot be called from future
return;
}
//collects all leads which need to be evaluated for clean address
List<Id> evaluateAddressAccountList = new List<Id>();
for (Account newAccount:newAccounts)
{
boolean isEmptyAddress = AddressUtility.isEmptyAddress(newAccount, AddressUtility.AccountShippingFieldsMap);
if (isEmptyAddress == null)
{
// System.debug('Address is null for incoming Account');
continue;
}
InformaticaStandardAddress stdAddr = null;
if (op.equals('INSERT'))
{
// System.debug('Coming in for first time insert without empty address for lead object:' + newAccount);
evaluateAddressAccountList.add(newAccount.id);//this is called from after insert, so id will be there always
}
else if (op.equals('UPDATE'))
{
// System.debug('Coming in as update');
Account oldAccount = oldMap.get(newAccount.id);
boolean isAddressChanged = AddressUtility.isAddresssChanged(oldAccount, newAccount, AddressUtility.AccountShippingFieldsMap);
// System.debug('isAddressChanged:' + isAddressChanged);
if (isAddressChanged == true)
{
evaluateAddressAccountList.add(newAccount.id);//this is called from after insert/after update, so id will be there always
}
}
//Call Informatica API and clean addresses
}
if(!evaluateAddressAccountList.isEmpty())
{
AddressUtility.cleanAccountShippingAddress(evaluateAddressAccountList);
}
}
//Create Notes on Account Starategy Change
public static void createNotesOnAccountStrategyupdate(List<Account> oldAccounts, List<Account> newAccounts,
Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap)
{
List<ContentVersion> NotesList = new List<ContentVersion>();
for (Account newAccount:newAccounts)  {
//|| (newAccount.Account_Strategy__c != oldAccountsMap.get(newAccount.Id).Account_Strategy_Notes__c)
if(newAccount.Account_Strategy_Notes__c != null && ((newAccount.Account_Strategy_Notes__c != oldAccountsMap.get(newAccount.Id).Account_Strategy_Notes__c)
)){
ContentVersion objCntNote = new ContentVersion();
objCntNote.Title = newAccount.Account_Strategy__c;
objCntNote.PathOnClient = objCntNote.Title + '.snote';
objCntNote.VersionData = Blob.valueOf((newAccount.Account_Strategy_Notes__c).escapeHtml4());
objCntNote.FirstPublishLocationId = newAccount.id;  // ParentId
NotesList.add(objCntNote);
//insert objCntNote;
}
}
if(NotesList.size()>0) {
// Schema.DescribeSObjectResult ds = ContentVersion.sObjectType.getDescribe();
//if( ds.isCreateable() ){}
insert NotesList;
}
}
/* Commented Out for HRP - 10016 --> Start
* JIRA Ticket: HRP - 795,
* Description: Designate Drives in the System to Include or Exclude from Future Calendar Build
public static void checkRolloverFlagUpdateAccessability( List<Account> oldAccounts, List<Account> newAccounts,Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap){
Map<Id, Id> accIdDistrictmanagerId = new Map<Id, Id>();
Map<Id, String> teammemberIdRoleMap = new Map<Id, String>();
Map<String, Decimal> roleRankMap = new Map<String, Decimal>();
Set<Id> teammemberids = new Set<Id>();
Set<Id> accountid = new Set<Id>();
List<AccountTeammember> aTeam ;
Id runninguserid = userInfo.getUserId();
Integer runningUserRank;
for( Account acc : newAccounts ){
if( !accIdDistrictmanagerId.containsKey( acc.Id ) ){
accIdDistrictmanagerId.put( acc.Id, acc.District_Manager__c);
accountid.add(acc.Id);
}
}
teammemberids.add( userInfo.getUserId() );
for( Id accid : accIdDistrictmanagerId.keySet() ){
if( accIdDistrictmanagerId.get( accid ) !=null ){
teammemberids.add( accIdDistrictmanagerId.get( accid ) ) ;
}
}
aTeam = [ select AccountId, userId, TeamMemberRole from AccountTeammember where AccountId IN:accountid and userId IN: teammemberids];
for( AccountTeammember atm : aTeam ){
if( !teammemberIdRoleMap.containsKey( atm.userId ) ){
teammemberIdRoleMap.put( atm.userId, atm.TeamMemberRole );
}
}
// System.debug( 'teammemberIdRoleMap is : ' + teammemberIdRoleMap );
// Retrieve data from Custom Metadat Type AccountTeamRoleRank__mdt
List<AccountTeamRoleRank__mdt> atmrolemdt = [select Rank__c, Team_Role__c from AccountTeamRoleRank__mdt ];
for( AccountTeamRoleRank__mdt atmmdt : atmrolemdt ){
if( !roleRankMap.containsKey( atmmdt.Team_Role__c ) ){
roleRankMap.put( atmmdt.Team_Role__c, atmmdt.Rank__c );
}
}
// System.debug( 'roleRankMap is: ' + roleRankMap );
// System.debug( 'running userid is: ' + runninguserid );
runningUserRank = Integer.valueOf( roleRankMap.get( teammemberIdRoleMap.get( runninguserid ) )  );
// System.debug('runningUserRank is ' + runningUserRank );
for( Account acc : newAccounts ){
// System.debug( 'old value of Always_Roll__c ' +  oldAccountsMap.get(acc.Id).Always_Roll__c  );
// System.debug( 'new value of Always_Roll__c ' +  acc.Always_Roll__c  );
if( acc.District_Manager__c != null && ((oldAccountsMap.get(acc.Id).Always_Roll__c != acc.Always_Roll__c)   || (oldAccountsMap.get(acc.Id).Do_Not_Roll__c != acc.Do_Not_Roll__c)) ){
Integer dmRank = Integer.valueOf( roleRankMap.get( teammemberIdRoleMap.get( acc.District_Manager__c ) )  );
// System.debug('dmRank is ' + dmRank + ' rank of running user ' + runningUserRank  );
if( runningUserRank > dmRank ){
acc.addError( 'You are not allowed to modify Always roll or Do not Roll field' );
}
}
}
}
Commented Out for HRP - 10016 --> End */
/*
* JIRA Ticket: HRP - 1678,
* Description: Populate Market field on Account based on Billing Zip code - Market Mapping
*/
public static void populateMarketOnAccount( List<Account> oldAccounts, List<Account> newAccounts,Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap){
List<Account> beforeInsertAccList = new List<Account>();
List<Account> beforeUpdateAccList = new List<Account>();
Set<Decimal> zipcodeset = new Set<Decimal>();
Set<String> zipCodeStringSet = new Set<String>();
for(Account newAccount:newAccounts){
if( newAccount.Id == null ){ // before insert scenario
beforeInsertAccList.add( newAccount );
}else if( newAccount.Id != null ){ // before update scenario
beforeUpdateAccList.add( newAccount );
}
}
if( !beforeInsertAccList.isEmpty() ){
for( Account newAccount:beforeInsertAccList  ){
if( newAccount.BillingPostalCode != null){
zipcodeset.add( Integer.valueOf( newAccount.BillingPostalCode ) );
zipCodeStringSet.add(String.valueOf(newAccount.BillingPostalCode));
}
}
}else if( !beforeUpdateAccList.isEmpty() ){
for( Account newAccount:beforeUpdateAccList  ){
if( newAccount.BillingPostalCode != null &&
oldAccountsMap.get(newAccount.id).BillingPostalCode !=newAccount.BillingPostalCode){//HRP-10005
zipcodeset.add( Decimal.valueOf( newAccount.BillingPostalCode ) );
zipCodeStringSet.add(String.valueOf(newAccount.BillingPostalCode));
}
}
}
if( !zipcodeset.isEmpty() ){
Map<String, String> zipcodeAndMarketMap = new Map<String, String>();
List< ARC_Market_Mapping__c > ARCMarketingMappObject = [ SELECT ID,
Zip_Code__c,
Market__c
FROM ARC_Market_Mapping__c
WHERE Zip_Code__c IN:zipCodeStringSet ];
System.debug('zipcodeset->'+zipcodeset);
System.debug('ARCMarketingMappObject->'+ARCMarketingMappObject);
if( !ARCMarketingMappObject.isEmpty() ){
for( ARC_Market_Mapping__c marketvar : ARCMarketingMappObject ){
zipcodeAndMarketMap.put( marketvar.Zip_Code__c, marketvar.Market__c );
}
}
for( Account newAccount: newAccounts ){
if(newAccount.BillingPostalCode  !=  null){
newAccount.Market__c = zipcodeAndMarketMap.get( String.valueOf( newAccount.BillingPostalCode ) ) ;
}
}
}
}
public static void updateNationalNameStatus(List<Account> newAccounts, Map<Id,Account> oldAccountsMap, Map<Id,Account> newAccountsMap)
{
String profileNameUserInfo;
List<String> allowedProfiles = System.Label.NationalNameAllowedProfiles.split(','); //HRP-9880
//Set<String> allowedProfiles = new Set<String>{'APS Planner','APS Admin','APS Management'};
//List<User> loggedInUser = [ SELECT ID , Profile.Name FROM User Where id = : UserInfo.getUserId() AND Profile.Name IN :allowedProfiles];
//Don't check for profile if the running user is "automated process"
if(UserInfo.getName() != System.Label.NationalNameUpdateExcludeUser) { //HRP-9880
profileNameUserInfo = [SELECT Id,Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
}//HRP-9880
for(Account accObj : newAccounts){
if( oldAccountsMap.get(accObj.Id).National_Name__c == null && accObj.National_Name__c != null){
accObj.Initial_Reviewer__c = UserInfo.getUserId();
accObj.National_Name_Status__c = System.Label.Initial_Review_Pending;
}else if(accObj.National_Name_Status__c == System.Label.Second_Review_Pending && accObj.National_Name__c != null && oldAccountsMap.get(accObj.Id).National_Name__c != null && accObj.National_Name__c != oldAccountsMap.get(accObj.Id).National_Name__c){
accObj.Initial_Reviewer__c = UserInfo.getUserId();
accObj.National_Name_Status__c = System.Label.Initial_Review_Pending;
accObj.National_Name_Initial_Review_Date__c = null;
}else if(accObj.National_Name_Status__c == System.Label.Review_Completed && accObj.National_Name__c != oldAccountsMap.get(accObj.Id).National_Name__c){
if(!string.isEmpty(profileNameUserInfo) && !allowedProfiles.contains(profileNameUserInfo))
accObj.adderror(System.Label.NationalNameCannotBeUpdatedAfterReview);
}
}
}
//Added for HRP-999
//Below method will add AccountTeamMembers to the Account when an Account is inserted and also populate the Account_Portfolio_Assignment__c Object based on ZIPCode of Account
public static List<Account_Portfolio_Assignment__c> createAccountTeamMembers(List<Account> newAccounts,Map<Id,Account> newAccountsMap,String calledFromBatch,Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap,Map<String,AccountTeamMember> teamMemberMap){//HRP-11138 return type void --> accountPortfolio Assignment
//System.debug('createAccountTeamMembers Method entered');
//System.debug('isMethodExecuted:'+isMethodExecuted);
BSF_Constants.isTeamMemberCreatedFromBackend = true;
//system.debug('AccountPortfoliosForTheAccount### '+AccountPortfoliosForTheAccount.values());
List<Id> accountIdList = new List<id>();
map<id,id> accIdExAP = new map<id,id>();
if(newAccountsMap!=null)
{
List<Account_Portfolio_Assignment__c> existingAccPortAssg = [select id, Account__c from Account_Portfolio_Assignment__c where Account__c IN:newAccountsMap.keyset()];
System.debug('newAccountsMap '+newAccountsMap);
System.debug('existingAccPortAssg '+existingAccPortAssg);
if(calledFromBatch =='')
{
for(Account_Portfolio_Assignment__c ap: existingAccPortAssg)
{
accIdExAP.put(ap.Account__c,ap.id);
}
}
system.debug('accIdExAP '+accIdExAP);
}
if (!System.isFuture() && calledFromBatch == '' && !Test.isRunningTest()){
//System.debug('isFuture:'+System.isFuture());
//System.debug('calledFromBatch:'+calledFromBatch);
//System.debug('inside isFuture if block');
return null;//HRP-11138 returning null
}
//add else
List<Account_Portfolio_Assignment__c> accPortfolioList = new List<Account_Portfolio_Assignment__c>();
if(!isMethodExecuted){
Map<Id,Account> accountPortfoliosForTheAccount = new Map<Id,Account>([select Id,Name,(select Id, Name from AccountPortfolioAssignments__r Limit 1) from Account where Id IN:newAccounts]);
system.debug('accountPortfoliosForTheAccount## '+accountPortfoliosForTheAccount);
system.debug('entered isMethodExecuted');
Set<String> zipCodeSet = new Set<String>();
system.debug('zipCodeSet'+zipCodeSet);
Map<String,List<Account>> zipCodeAccListMap = new Map<String,List<Account>>();
Map<Id,List<Date>> accIdGapDatesMap= new Map<Id,List<Date>>();
for(Account acc:newAccounts){
if(!accountIdList.contains(acc.id))
{
accountIdList.add(acc.id);
}
String zip = String.isBlank(acc.BillingPostalCode) ? acc.ShippingPostalCode :acc.BillingPostalCode;
zipCodeSet.add(zip);
system.debug('zipCodeSet'+zipCodeSet);
if(!zipCodeAccListMap.containsKey(zip)){
List<Account> accList = new List<Account>();
accList.add(acc);
zipCodeAccListMap.put(zip, accList);
}
else{
zipCodeAccListMap.get(zip).add(acc);
}
}
//HRP-12053 Start
if(calledFromBatch== BSF_constants.DEFAULT_TERRITORY)
{
set<id> exceptionId = new set<Id>();
for(Account_Portfolio_Assignment__c accException : accIdAccPortfolioMap.values())
{
exceptionId.add(accException.id);
}
List<Account_Portfolio_Assignment__c> exAccPortList =[select id,Account__c,BSF_portfolio__c,start_date__c,End_Date__c from Account_Portfolio_Assignment__c where account__c in:accIdAccPortfolioMap.keySet() and bsf_portfolio__r.Taxonomy_type__c in('Bio Recruitment CD','Bio Account Portfolio') and Id not in :exceptionId];
Map<Id,List<Account_Portfolio_Assignment__c>> accIdAccPortListMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
for(Account_Portfolio_Assignment__c apa:exAccPortList)
{
if(!accIdAccPortListMap.containsKey(apa.Account__c))
{
accIdAccPortListMap.put(apa.Account__c,new List<Account_Portfolio_Assignment__c>());
}
accIdAccPortListMap.get(apa.Account__c).add(apa);
}
date maxDate=Date.newInstance(4000,12,31);
for(Id accId : accIdAccPortfolioMap.keySet())
{
Integer i = 0;
if(accIdAccPortListMap.containsKey(accId))
{
while(i<accIdAccPortListMap.get(accId).size())
{
Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c();
apa = accIdAccPortListMap.get(accId)[i];
system.debug('testing accexception '+accIdAccPortfolioMap.get(apa.Account__c));
system.debug('testing apa '+apa);
if(apa.start_Date__c > accIdAccPortfolioMap.get(apa.Account__c).End_date__c && apa.start_Date__c != accIdAccPortfolioMap.get(apa.Account__c).End_date__c+1)
{
system.debug('Have next to exception');
if(!accIdGapDatesMap.containsKey(apa.Account__c))
{
accIdGapDatesMap.put(apa.Account__c,new List<Date>{accIdAccPortfolioMap.get(apa.Account__c).End_date__c+1,apa.start_Date__c-1});
}
}
else if(i==accIdAccPortListMap.get(accId).size()-1 && !accIdGapDatesMap.containsKey(apa.Account__c) && apa.End_Date__c!=maxDate)
{
system.debug('doesnt Have next to exception');
accIdGapDatesMap.put(apa.Account__c,new List<Date>{accIdAccPortfolioMap.get(apa.Account__c).End_date__c+1});
}
i++;
}
}
else
{
system.debug('no existing assignment');
accIdGapDatesMap.put(accId,new List<Date>{accIdAccPortfolioMap.get(accId).End_date__c+1});
}
}
system.debug('accIdGapDatesMap '+accIdGapDatesMap);
}
//HRP-12053 End
List<Taxonomy__c> taxonomyList = [SELECT Id,Zip_Code__c,Zip_Code_Key__c,Zip_Code_Name__c,Division_Code__c,DS_Region_Code__c,Team_Code__c,ABM_Code__c,ABM_Name__c,DRD_Territory_Code__c,DRD_Territory_Name__c,Start_Date__c,End_Date__c,RecordType.Name FROM Taxonomy__c WHERE Zip_Code__c  IN:zipCodeSet AND End_Date__c > TODAY AND RecordType.Name =:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ORDER BY Start_Date__c];
System.debug('taxonomyList: '+taxonomyList.size());
Set<String> externalKeySet = new Set<String>();
Map<String,Taxonomy__c> keyTaxoMap = new Map<String,Taxonomy__c>();
Map<String,List<String>> zipExternalKeyMap = new Map<String,List<String>>();
Map<String,BSF_Portfolio__c> portfolioMap = new Map<String,BSF_Portfolio__c>();
Map<String,List<Portfolio_Assignment__c>> portfolioUserMap = new Map<String,List<Portfolio_Assignment__c>>();
List<AccountTeamMember> allTeamMemberInsertList = new List<AccountTeamMember>();
for(Taxonomy__c taxonomy:taxonomyList){
String externalKey = null;
if(taxonomy.ABM_Name__c != null && taxonomy.ABM_Name__c != 'NA' && !taxonomy.ABM_Name__c.containsIgnoreCase(System.Label.NO_SBPM_ABM)){//HRP-13866 System.Label.NO_SBPM_ABM in place of hard coded value
externalKey = taxonomy.RecordType.Name+'_'+taxonomy.Division_Code__c +'_'+taxonomy.DS_Region_Code__c+'_'+taxonomy.Team_Code__c+'_'+taxonomy.ABM_Code__c+'_'+taxonomy.DRD_Territory_Code__c;
}else{
externalKey = taxonomy.RecordType.Name+'_'+taxonomy.Division_Code__c +'_'+taxonomy.DS_Region_Code__c+'_'+taxonomy.Team_Code__c+'_'+taxonomy.DRD_Territory_Code__c;
}
externalKeySet.add(externalKey);
if(keyTaxoMap.get(externalKey) != null){
keyTaxoMap.get(externalKey).End_Date__c = taxonomy.End_Date__c;
}else{
keyTaxoMap.put(externalKey,taxonomy);
}
if(zipExternalKeyMap.get(taxonomy.Zip_Code__c) == null){
system.debug('zipExternalKeyMap');
zipExternalKeyMap.put(taxonomy.Zip_Code__c,new List<String>());
}
zipExternalKeyMap.get(taxonomy.Zip_Code__c).add(externalKey);
system.debug('zipExternalKeyMap.get(taxonomy.Zip_Code__c).add(externalKey);'+zipExternalKeyMap.get(taxonomy.Zip_Code__c));
}
List<BSF_Portfolio__c> portfolioList = [SELECT Id,Name,Portfolio_Type__c,External_Key__c,External_Key_BackEnd__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c,End_Date__c,start_Date__c FROM BSF_Portfolio__c WHERE External_Key_BackEnd__c IN:externalKeySet AND End_Date__c >= TODAY order by createdDate desc];
Set<Id> portfolioIds = new Set<Id>();
Set<String> portfolioCodeSet = new Set<String>();
map<String,BSF_Portfolio__c> amPortfolioMap = new map<String,BSF_Portfolio__c>();//HRP-11290
for(BSF_Portfolio__c portfolio:portfolioList){
if(!portfolioMap.keyset().contains(portfolio.External_Key_BackEnd__c))
{
portfolioMap.put(portfolio.External_Key_BackEnd__c,portfolio);
}
amPortfolioMap.put(portfolio.portfolio_code__c,portfolio);//HRP-11290
portfolioIds.add(portfolio.Id); //AM ID
portfolioIds.add(portfolio.Parent_Portfolio__c); //ABM ID
portfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__c); //DM ID
portfolioCodeSet.add(portfolio.Portfolio_Code__c);
}
//HRP-12053 commented Start
/*List<BSF_Portfolio__c> supervisorAMPortfolios = [SELECT Name,Portfolio_Type__c,Taxonomy_Type__c,External_Key__c,
Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__c,End_Date__c,start_Date__c FROM BSF_Portfolio__c
WHERE Portfolio_Code__c IN:portfolioCodeSet
AND Taxonomy_Type__c =: BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE];//HRP-11290 start & End Dates in Query
Map<String,Id> portfolioCodeIdMap = new Map<String,Id>();
Map<Id,Id> amSupervisorPortfolioIdMap = new Map<Id,Id>();
Map<id,BSF_Portfolio__c> superIdSuperBsfMap = new Map<id,BSF_Portfolio__c>();
//System.debug('supervisorAMPortfolios: '+supervisorAMPortfolios);
if(supervisorAMPortfolios.size()>0){
for(BSF_Portfolio__c supervisorAMPortfolio:supervisorAMPortfolios){
if(amPortfolioMap != null && amPortfolioMap.get(supervisorAMPortfolio.portfolio_code__c)!= null && !(supervisorAMPortfolio.end_Date__c < amPortfolioMap.get(supervisorAMPortfolio.portfolio_code__c).start_Date__c || supervisorAMPortfolio.Start_Date__c > amPortfolioMap.get(supervisorAMPortfolio.portfolio_code__c).End_Date__c))//11290 portolio code date check
portfolioCodeIdMap.put(supervisorAMPortfolio.Portfolio_Code__c,supervisorAMPortfolio.Id);
amSupervisorPortfolioIdMap.put(supervisorAMPortfolio.Id, supervisorAMPortfolio.Parent_Portfolio__c);
superIdSuperBsfMap.put(supervisorAMPortfolio.Id,supervisorAMPortfolio);
portfolioIds.add(supervisorAMPortfolio.Parent_Portfolio__c);
}
}
//System.debug('portfolioCodeIdMap: '+portfolioCodeIdMap);
//Get the Supervisor Taxonomy
List<Taxonomy__c> supervisorTaxonomoies = [SELECT Id,Portfolio_Code__c,Portfolio_Name__c,
Supervisor_Code__c,Supervisor_Name__c,
Start_Date__c,End_Date__c,RecordType.Name
FROM Taxonomy__c
WHERE Portfolio_Code__c IN:portfolioCodeIdMap.keySet()
AND End_Date__c > TODAY
AND RecordType.Name =:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE
ORDER BY Start_Date__c];
Map<String,Taxonomy__c> portfolioCodeTaxonomyMap = new Map<String,Taxonomy__c>();
for(Taxonomy__c supervisorTaxo:supervisorTaxonomoies){
portfolioCodeTaxonomyMap.put(supervisorTaxo.Portfolio_Code__c,supervisorTaxo);
}*/
//HRP-12053 commented End
List<Portfolio_Assignment__c> portFolioUsers = [Select Id,Name, User__c ,Start_Date__c ,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c  FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN :portfolioIds AND End_Date__c > TODAY ORDER BY Start_Date__c];
for(Portfolio_Assignment__c portfolioUser:portFolioUsers){
if(portfolioUserMap.get(portfolioUser.BSF_Portfolio__c) == null){
portfolioUserMap.put(portfolioUser.BSF_Portfolio__c,new List<Portfolio_Assignment__c>());
}
portfolioUserMap.get(portfolioUser.BSF_Portfolio__c).add(portfolioUser);
}
System.debug(' zipCodeAccListMap: '+zipCodeAccListMap);
System.debug(' zipExternalKeyMap: '+zipExternalKeyMap);
System.debug(' keyTaxoMap: '+keyTaxoMap);
System.debug(' portfolioMap: '+portfolioMap);
for(String zipCode:zipCodeAccListMap.keySet()){
List<Account> accList = zipCodeAccListMap.get(zipCode);
// system.debug('the zip code### '+zipCode);
// system.debug('account for that zip code ## '+accList);
for(Account acc:accList){
//system.debug('entered accList '+acc);
List<String> externalKeyList = zipExternalKeyMap.get(zipCode);
//system.debug('externalKeyList '+externalKeyList);
if(externalKeyList == null || externalKeyList.isEmpty())
continue; //No Portfolios identified for the given zipcode
Account queriedAccount = accountPortfoliosForTheAccount.get(acc.Id);
//system.debug('queriedAccount '+queriedAccount);
/*HRP-12485
if( queriedAccount.Account_AM_Portfolio_Type__c  ||
(queriedAccount.AccountPortfolioAssignments__r != null && queriedAccount.AccountPortfolioAssignments__r.size() > 0)){
// system.debug('entered123');
//continue;
}
HRP-12485*/
//system.debug('entered234');
List<AccountTeamMember> amList = new List<AccountTeamMember>();
List<AccountTeamMember> dmList = new List<AccountTeamMember>();
List<AccountTeamMember> abmList = new List<AccountTeamMember>();
List<AccountTeamMember> supervisorList = new List<AccountTeamMember>();
Set<id> exceptionDoneAccIdeSet = new Set<id>();
Account_Portfolio_Assignment__c prevAccPortAssign = new Account_Portfolio_Assignment__c();
for(String externalKey:externalKeyList){
AccountTeamMember prevAM = null;
AccountTeamMember prevDM = null;
AccountTeamMember prevABM = null;
AccountTeamMember prevSupervisor = null;
Taxonomy__c taxoRecord = keyTaxoMap.get(externalKey);
if(!portfolioMap.keyset().contains(externalKey))//HRP-8897 spot fix
continue;
BSF_Portfolio__c portfolio = portfolioMap.get(externalKey);
Account_Portfolio_Assignment__c accPortfolio = new Account_Portfolio_Assignment__c();
accPortfolio.Account__c = acc.Id;
accPortfolio.BSF_Portfolio__c = portfolio.Id;
if((calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService'))||
(calledFromBatch== BSF_constants.DEFAULT_TERRITORY)){
//HRP-12053 Start
if(accIdGapDatesMap==null ||(accIdGapDatesMap!=null && !accIdGapDatesMap.containsKey(accPortfolio.Account__c)  ))
{
system.debug('accPortfolioList break '+accPortfolioList);
break;
}
if(taxoRecord.End_Date__c<accIdAccPortfolioMap.get(acc.Id).End_Date__c)
continue;
if(!exceptionDoneAccIdeSet.contains(accPortfolio.Account__c))
{
accPortfolio.Start_Date__c = accIdAccPortfolioMap.get(acc.Id).End_Date__c +1;
exceptionDoneAccIdeSet.add(accPortfolio.Account__c);
system.debug('exceptionDoneAccIdeSet');
}
else
{
accPortfolio.Start_Date__c = taxoRecord.Start_Date__c;
}
//HRP-12053 End
}
else{
accPortfolio.Start_Date__c = taxoRecord.Start_Date__c;
}
accPortfolio.End_Date__c = taxoRecord.End_Date__c;
//  accPortfolio.External_Identifier__c = String.valueOf(acc.Id)+ '_' + String.valueOf(portfolio.Id) + '_' + String.valueOf(territoryCodeZipCodeMap.get(portfolio.Portfolio_Code__c).Start_Date__c) +  '_' + String.valueOf(territoryCodeZipCodeMap.get(portfolio.Portfolio_Code__c).End_Date__c);
system.debug('prevAccPortAssign'+prevAccPortAssign);
system.debug('accPortfolio'+accPortfolio);
if(prevAccPortAssign != null){
if(prevAccPortAssign.BSF_Portfolio__c == accPortfolio.BSF_Portfolio__c){
prevAccPortAssign.End_Date__c = taxoRecord.End_Date__c;
continue;
}
else
{
prevAccPortAssign.End_Date__c = accPortfolio.Start_Date__c - 1;
}
}
prevAccPortAssign = accPortfolio;
accPortfolioList.add(accPortfolio);
//HRP-12053 Start
if(accIdGapDatesMap!=null && accIdGapDatesMap.containsKey(accPortfolio.Account__c) &&  calledFromBatch== BSF_constants.DEFAULT_TERRITORY && accIdGapDatesMap.get(accPortfolio.Account__c).size()==2)
{
system.debug('accPortfolioList break '+accPortfolioList);
break;
}
//HRP-12053 end
//HRP-12053 commented Start
/*
//Check for Supervisor--As part Of HRP-4622--Starts
// System.debug('portfolio.Portfolio_Code__c: '+portfolio.Portfolio_Code__c);
// System.debug('portfolioCodeIdMap: '+portfolioCodeIdMap);
if(portfolioCodeIdMap.containsKey(portfolio.Portfolio_Code__c)){
Account_Portfolio_Assignment__c supervisorAccAMPortfolio = new Account_Portfolio_Assignment__c();
supervisorAccAMPortfolio.Account__c = acc.Id;
supervisorAccAMPortfolio.BSF_Portfolio__c = portfolioCodeIdMap.get(portfolio.Portfolio_Code__c);
BSF_Portfolio__c superBsf = superIdSuperBsfMap.get(portfolioCodeIdMap.get(portfolio.Portfolio_Code__c));//HRP-11290
if((calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService'))
|| (calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper'))){
supervisorAccAMPortfolio.Start_Date__c = accIdAccPortfolioMap.get(acc.Id).End_Date__c +1;
}
else{
if(portfolioCodeTaxonomyMap.containsKey(portfolio.Portfolio_Code__c) && portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).Start_Date__c != null)
{
supervisorAccAMPortfolio.Start_Date__c = portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).Start_Date__c>=portfolio.start_Date__c?portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).Start_Date__c:portfolio.start_Date__c;//HRP-11290 date comparison
}
else{
supervisorAccAMPortfolio.Start_Date__c = taxoRecord.Start_Date__c>=superBsf.start_Date__c?taxoRecord.Start_Date__c:superBsf.start_Date__c;//HRP-11290 comparison
}
}
if(portfolioCodeTaxonomyMap.containsKey(portfolio.Portfolio_Code__c) && portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).End_Date__c != null)
{
supervisorAccAMPortfolio.End_Date__c = portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).End_Date__c<=portfolio.End_Date__c?portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).End_Date__c:portfolio.End_Date__c;//HRP-11290 comparison
}
else{
supervisorAccAMPortfolio.End_Date__c = taxoRecord.End_Date__c<=superBsf.End_Date__c?taxoRecord.End_Date__c:superBsf.End_Date__c;//HRP-11290 comparison
}
System.debug('supervisorAccAMPortfolio: '+supervisorAccAMPortfolio);
//accPortfolioList.add(supervisorAccAMPortfolio);
}
//Check for Supervisor--As part Of HRP-4622--Ends
//Start - Populate Team Members
//For Supervisor--Added as Part of HRP-4622--Changes Starts
List<Portfolio_Assignment__c> supervisorUsers = portfolioUserMap.get(amSupervisorPortfolioIdMap.get(portfolioCodeIdMap.get(portfolio.Portfolio_Code__c)));
if( supervisorUsers != null && supervisorUsers.size() > 0){
if(portfolioCodeTaxonomyMap.containsKey(portfolio.Portfolio_Code__c) && portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c).Start_Date__c != null){
Taxonomy__c supervisorTaxoRecord = portfolioCodeTaxonomyMap.get(portfolio.Portfolio_Code__c);
prevSupervisor = populateAccountTeamMembersByPortfolio(acc,supervisorTaxoRecord,BSF_Constants.SUPERVISOR,supervisorUsers,supervisorList,prevSupervisor,calledFromBatch,accIdAccPortfolioMap);
}
else{
prevSupervisor = populateAccountTeamMembersByPortfolio(acc,taxoRecord,BSF_Constants.SUPERVISOR,supervisorUsers,supervisorList,prevSupervisor,calledFromBatch,accIdAccPortfolioMap);
}
}
//System.debug('prevSupervisor: '+prevSupervisor);
//For Supervisor--Added as Part of HRP-4622--Changes Ends
List<Portfolio_Assignment__c> amUsers = portfolioUserMap.get(portfolio.Id);
if( amUsers != null && amUsers.size() > 0){
prevAM = populateAccountTeamMembersByPortfolio(acc,taxoRecord,BSF_Constants.ACCOUNT_MANAGER,amUsers,amList,prevAM,calledFromBatch,accIdAccPortfolioMap);
}
if(taxoRecord.ABM_Name__c != null && taxoRecord.ABM_Name__c != 'NA' && !taxoRecord.ABM_Name__c.containsIgnoreCase('No ABM')){
List<Portfolio_Assignment__c> abmUsers = portfolioUserMap.get(portfolio.Parent_Portfolio__c);
prevABM = populateAccountTeamMembersByPortfolio(acc,taxoRecord,BSF_Constants.AREA_BOOKING_MANAGER,abmUsers,abmList,prevABM,calledFromBatch,accIdAccPortfolioMap);
List<Portfolio_Assignment__c> dmUsers = portfolioUserMap.get(portfolio.Parent_Portfolio__r.Parent_Portfolio__c);
prevDM = populateAccountTeamMembersByPortfolio(acc,taxoRecord,BSF_Constants.DISTRICT_MANAGER,dmUsers,dmList,prevDM,calledFromBatch,accIdAccPortfolioMap);
}else{
List<Portfolio_Assignment__c> dmUsers = portfolioUserMap.get(portfolio.Parent_Portfolio__c);
prevDM = populateAccountTeamMembersByPortfolio(acc,taxoRecord,BSF_Constants.DISTRICT_MANAGER,dmUsers,dmList,prevDM,calledFromBatch,accIdAccPortfolioMap);
}
}
//System.debug('supervisorList: '+supervisorList);
allTeamMemberInsertList.addAll(amList);
allTeamMemberInsertList.addAll(dmList);
allTeamMemberInsertList.addAll(abmList);
allTeamMemberInsertList.addAll(supervisorList);
*///HRP-12053 end
}
}
System.debug('accPortfolioList:' +accPortfolioList.size());
System.debug('accPortfolioList:' +accPortfolioList);}
list<Account_Portfolio_Assignment__c> apInsertListToUpdate = new list<Account_Portfolio_Assignment__c>();
list<Account_Portfolio_Assignment__c> apInsertList = new list<Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c ap:accPortfolioList)
{
account acc = new account();
if(newAccountsMap!=null && newAccountsMap.get(ap.Account__c)!=null)
acc =newAccountsMap.get(ap.Account__c);
if(calledFromBatch!= BSF_constants.DEFAULT_TERRITORY && (accIdExAP!= null && accIdExAP.get(ap.Account__c)!= null) &&
((acc !=null && acc.Zipcode_change__c != null && ((acc.billingpostalcode !=null && acc.Zipcode_change__c !=acc.billingpostalcode) || (acc.billingpostalcode ==null && acc.shippingpostalcode != null && acc.Zipcode_change__c !=acc.shippingpostalcode)))))//HRP-10878;//HRP-12053 acc.Zipcode_change__c != null
{
system.debug(accIdExAP.get(ap.Account__c));
apInsertListToUpdate.add(ap);
}
else if(accIdExAP==null || accIdExAP.get(ap.Account__c)== null || calledFromBatch== BSF_constants.DEFAULT_TERRITORY)//HRP-10878; //HRP-12053 calledFromBatch check
{
system.debug('accIdExAP is null');
apInsertList.add(ap);
}
}
if(calledFromBatch!='AccportDelete')//HRP-11138 doesn't needed when exception delete
{
if(!apInsertListToUpdate.isEmpty())
AccountPortfolioAssignmentService.handleTerritoryPortfolioInsert(apInsertListToUpdate);//HRP-10878
system.debug('apInsertListToUpdate'+apInsertListToUpdate);
BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');//HRP-12053 trigger not need specilaist handle below calling HandleAccountSpecialist
system.debug('insertResults'+apInsertList);
Database.SaveResult[] insertResults = Database.insert(apInsertList,false);
BSF_Constants.skipAccountPortfolioAssignmentTrigger = false;
for(Database.SaveResult saveResult:insertResults){
System.debug('saveResult: '+saveResult.isSuccess());
System.debug('saveResult errors: '+saveResult.getErrors());
}
//Log errors for any failures
//BSF Error log - success log
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(insertResults, 'AccountPortfolioAssign','AccountService','createAccountTeamMembers','Error','error in creating AccPortAssign');
InsertBsfErrorLog.insertBsfErrors(logList);
//BSF Error log - success log - completed
/*if(teamMemberMap != null){
for(AccountTeamMember teammemberNew:allTeamMemberInsertList){
if(teamMemberMap.containsKey(teammemberNew.AccountId+''+teammemberNew.UserId)){
// System.debug('teammemberNew '+teammemberNew);
AccountTeamMember removedTeamMember = teamMemberMap.remove(teammemberNew.AccountId+''+teammemberNew.UserId);
// System.debug('removedTeamMember '+removedTeamMember);
teammemberNew.Start_Date__c = removedTeamMember.Start_Date__c;
}}
}*/
//System.debug('allTeamMemberInsertList: '+allTeamMemberInsertList);
//HRP-10099 && HRP-8897
map<string,AccountTeamMember> accIdUserDate = new map<string,AccountTeamMember> ();//Map value changed from list of dates to AccountTeamMember
if(accIdAccPortfolioMap!=null)
{
accountIdList.addAll(accIdAccPortfolioMap.keyset());
}
AccountPortfolioAssignmentService.HandleAccountSpecialist(new set<id>(accountIdList));//HRP-6028
AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(accountIdList,null,new set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());//HRP-10569 parameter changes
//HRP-10099 && HRP-8897
}
/*HRP-8897
List<AccountTeamMember> ZipcodeAccTeam = new List<AccountTeamMember> ();
if(!apInsertListToUpdate.isEmpty())
{
system.debug('Zipcode changed');
ZipcodeAccTeam = AccountPortfolioAssignmentService.AccZipcodeChangeTeamHandle(apInsertListToUpdate,allTeamMemberInsertList);
}
if(!ZipcodeAccTeam.isEmpty())
{
allTeamMemberInsertList.clear();
allTeamMemberInsertList.addAll(ZipcodeAccTeam);
}
//HRP-10099
for(AccountTeamMember atm:allTeamMemberInsertList)
{
string Key = atm.AccountId+'_'+atm.userid;
if(accIdUserDate.containsKey(Key))
{
AccountTeamMember acctm = accIdUserDate.get(key);
system.debug('atm**'+atm);
system.debug('acctm**'+acctm);
if(atm.Start_Date__c != acctm.Start_Date__c)
{
atm.Start_Date__c = acctm.Start_Date__c;
}
if(atm.End_Date__c != acctm.End_Date__c)
{
atm.End_Date__c = acctm.End_Date__c;
}
//HRP-8897
if(atm.BSF_Portfolio__c != acctm.BSF_Portfolio__c)
{
atm.BSF_Portfolio__c = acctm.BSF_Portfolio__c;
}
//HRP-8897
}
}
//HRP-10099
Database.SaveResult[] insertTeamResults = Database.insert(allTeamMemberInsertList,false);
logList = BSF_Utilities.createErrorLog(insertTeamResults, 'Populate Account Team','AccountService','CreateAccTeam','Error','Error in upserting accTeam');
Database.insert(logList,false);*///HRP-8897
}
isMethodExecuted = true;
return accPortfolioList;
}
public static AccountTeamMember populateAccountTeamMembersByPortfolio(Account acc,Taxonomy__c taxoRecord,String portfolioType,List<Portfolio_Assignment__c> portUsers,List<AccountTeamMember> teamMemberList,AccountTeamMember prevMember,String calledFromBatch,Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap){
for(Integer index=teamMemberList.size()-1;index>=0;index--){
if(teamMemberList[index].Start_Date__c > taxoRecord.Start_Date__c){
teamMemberList.remove(index);
}else{
teamMemberList[index].End_Date__c = taxoRecord.Start_Date__c -1;
break;
}
}
set<id> accidSet = new set<id>();
if(accIdAccPortfolioMap != null)
{
accidset.addAll(accIdAccPortfolioMap.keyset());
}
else
{
accidSet.add(acc.id);
}
Map<id,List<id>> accAccTeamListMap =BsfPortfolioSyncHelper.accIdexistingUserIdMap(accidSet);
if(portUsers != null){
for(Portfolio_Assignment__c userAssignment:portUsers){
Date userAssignStDate = userAssignment.Start_Date__c;
Date teamMemStartDate;
if(teamMemberList.size() > 0 && teamMemberList[teamMemberList.size()-1].UserId == userAssignment.User__c){
teamMemberList[teamMemberList.size()-1].End_Date__c = userAssignment.End_Date__c;
continue;
}
AccountTeamMember member1 = new AccountTeamMember(AccountId=acc.Id);
if(accIdAccPortfolioMap != null && accIdAccPortfolioMap.get(acc.Id)!=null)
{
teamMemStartDate = (accIdAccPortfolioMap.get(acc.Id).End_Date__c +1 >= userAssignStDate?accIdAccPortfolioMap.get(acc.Id).End_Date__c+1:userAssignStDate);
}
if((accAccTeamListMap == null || accAccTeamListMap.get(acc.Id) == Null) ||
(accAccTeamListMap != null && accAccTeamListMap.get(acc.Id) != null
&& !accAccTeamListMap.get(acc.Id).contains(userAssignment.user__c)))
{
system.debug('inside accAccTeamListMap'+accAccTeamListMap.get(acc.Id));
if(prevMember == null){
/*if(calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper')){
member1.Start_Date__c = System.Today() +1;
}*/
if((calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService'))
|| (calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper'))) {
member1.Start_Date__c = teamMemStartDate;
}
else
{
member1.Start_Date__c = taxoRecord.Start_Date__c >= userAssignStDate?taxoRecord.Start_Date__c:userAssignStDate;
}
}else{
/*if(calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper')){
member1.Start_Date__c = System.Today() +1;
}*/
if((calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService'))
|| (calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper'))) {
member1.Start_Date__c = teamMemStartDate;
}
else{
member1.Start_Date__c = userAssignment.Start_Date__c;
}
}
}
member1.End_Date__c =userAssignment.End_date__c;
member1.TeamMemberRole = portfolioType;
member1.UserId = userAssignment.User__c;
member1.AccountAccessLevel= 'Edit';
member1.CaseAccessLevel = 'Edit';
member1.OpportunityAccessLevel = 'Edit';
member1.BSF_Portfolio__c = userAssignment.BSF_Portfolio__c;
//Commented For Ticket No : HRP-9699 [Start]
/*if(accAccTeamListMap == null || accAccTeamListMap.get(acc.Id) == Null)
{
member1.BSF_Portfolio__c = userAssignment.BSF_Portfolio__c;
}*/
//Commented For Ticket No : HRP-9699 [End]
teamMemberList.add(member1);
prevMember = member1;
}
}
return prevMember;
}

// User Story: 1485 :Updates to Account Preference Values
public static void validationForDaysOfWeekDeclined(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
//System.debug('---Enter----');
List<String> daysOfWeekDeclined = new List<String>();
List<String> daysOfWeekPreferred = new List<String>();
for (Account newAccount : newAccountList) {
Account oldAccount = oldAccountMap?.get(newAccount.Id);
if ((newAccount.Days_of_Week_Declined__c != oldAccount.Days_of_Week_Declined__c) || (newAccount.Days_of_Week_Preferred__c != oldAccount.Days_of_Week_Preferred__c)){
daysOfWeekDeclined.add(newAccount.Days_of_Week_Declined__c);
daysOfWeekPreferred.add(newAccount.Days_of_Week_Preferred__c);
}
}
set<string> aStringSet = new set<string>(daysOfWeekPreferred);
set<string> aStringSet1 = new set<string>(daysOfWeekDeclined);
aStringSet.remove(null);
aStringSet1.remove(null);
// System.debug('---daysOfWeekDeclined----'+aStringSet);
// System.debug('---daysOfWeekPreferred----'+aStringSet1);
if(aStringSet.size() > 0 && aStringSet1.size() > 0){
String[] compareDaysOfWeekDeclined = daysOfWeekDeclined[0].split(';');
System.debug('---compareDaysOfWeekDeclined----'+compareDaysOfWeekDeclined);
for(String comparePicklistValue : compareDaysOfWeekDeclined){
if(daysOfWeekPreferred[0].contains(comparePicklistValue)){
//System.debug('---comparePicklistValue----'+comparePicklistValue);
for (Account newAccount : newAccountList) {
//System.debug('---newAccount----'+newAccount);
newAccount.addError('Day of Week Declined and Days of Week Preferred not have same value');
}
}
}
}
}
// User Story: 1485 :Updates to Account Preference Values
public static void customNotofocationForDaysOfWeekDeclined(List<Account> newAccountList,Map<Id, Account> oldAccountMap) {
System.debug('**DaysOfWeekDeclinedMatchesDrivesDay**');
Map<Id,List<String>> mapOfdaysOfweekDec=new Map<Id,List<String>>();
for (Account acctRecord : newAccountList) {
System.debug('**DaysOfWeekDeclinedMatchesDrivesDay**');
if(oldAccountMap.get(acctRecord.id).Days_of_Week_Declined__c!=acctRecord.Days_of_Week_Declined__c && acctRecord.Days_of_Week_Declined__c!=null){
Map<String,String> mapOfOldDays=new Map<String,String>();
Map<String,String> mapOfnewDays=new Map<String,String>();
String oldDays=oldAccountMap.get(acctRecord.id).Days_of_Week_Declined__c;
String newDays=acctRecord.Days_of_Week_Declined__c;
if(oldDays!=null && oldDays.contains(';')){
String[] splitStrings = oldDays.split(';');
for(String s1:splitStrings){
mapOfOldDays.put(s1,s1);
}
}else if(oldDays!=null && !oldDays.contains(';')){
mapOfOldDays.put(oldDays,oldDays);
}
if(newDays!=null && newDays.contains(';')){
String[] splitStrings1 = newDays.split(';');
for(String s2:splitStrings1){
mapOfnewDays.put(s2,s2);
}
}else if(newDays!=null && !newDays.contains(';')){
mapOfnewDays.put(newDays,newDays);
}
List<String> listOfStrings=new List<String>();
for(String s:mapOfnewDays.keySet()){
if(!mapOfOldDays.containsKey(s)){
listOfStrings.add(s);
}
}
//System.debug('listOfStrings===='+listOfStrings);
if(!listOfStrings.isEmpty()){
mapOfdaysOfweekDec.put(acctRecord.id,listOfStrings);
}
}
}
if(!mapOfdaysOfweekDec.isEmpty()){
Map<Id, List<Opportunity>> mapOfAcctOppties = new Map<Id, List<Opportunity>>();
for(Opportunity op : [select id,Day_of_Week__c,Drive_Date__c,AccountId from Opportunity where AccountId In:mapOfdaysOfweekDec.keySet() and Drive_Date__c > TODAY]) {
if(mapOfAcctOppties.containsKey(op.AccountId)) {
List<Opportunity> listOfOprecord = mapOfAcctOppties.get(op.AccountId);
listOfOprecord.add(op);
mapOfAcctOppties.put(op.AccountId, listOfOprecord);
} else {
mapOfAcctOppties.put(op.AccountId, new List<Opportunity> {op});
}
}
if(!mapOfAcctOppties.isEmpty()){
for(Account acc:newAccountList){
if(mapOfdaysOfweekDec.containsKey(acc.id)){
List<String> listOfDays= mapOfdaysOfweekDec.get(acc.id);
Map<String,String> mapOfDays=new  Map<String,String>();
for(String s1:listOfDays){
mapOfDays.put(s1,s1);
}
if(mapOfAcctOppties.containsKey(acc.id)){
List<Opportunity> listOfOppties= mapOfAcctOppties.get(acc.id);
// CustomNotificationType cnotification = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType where DeveloperName='Account_Preference_Custom_Notification'];
Id CUstomNotificationTypeId = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType where DeveloperName='Account_Preference_Custom_Notification' LIMIT 1].Id;
List<String> userId = new List<String>();
BSF_CustomNotification notification;
for(Opportunity op:listOfOppties){
if(mapOfDays.containsKey(op.Day_of_Week__c)){
// Messaging.CustomNotification notification = new Messaging.CustomNotification();
// notification.setBody('Future blood drive opportunities are scheduled for this day of week');
// notification.setTitle('Future blood drive opportunities are scheduled for this day of week');
// notification.setSenderId(Userinfo.getUserId());
// notification.setNotificationTypeId(cnotification.Id);
// notification.setTargetId(acc.Id); // target object id
// try{
//     notification.send(new Set<String> { Userinfo.getUserId() }); // target user id.
//     Break;
// }
// catch(Exception e) {
//     System.debug('The following exception has occurred: ' + e.getMessage());
//     System.debug('Line number: '+e.getLineNumber());
// }
//Send Notification
//HRP-10482 changes starts here
notification = new BSF_CustomNotification()
.body('Future blood drive opportunities are scheduled for this day of week')
.title('Future blood drive opportunities are scheduled for this day of week')
.sender(Userinfo.getUserId())
.typeId(CUstomNotificationTypeId)
.target(acc.Id) // target object id
.category('DaysOfWeekDeclinedMatchesDrivesDay'); //HRP-12757
notification.send(new List<String>{Userinfo.getUserId()});
//HRP-10482 changes ends here
System.debug('**notification**'+notification);
}
}
}
}
}
}
}
}
/* HRP-5610
* Description: If Account Address not updated by Informatica service due to entirely incorrect address
* to do: create a Task, where Task owner is Account Manager
* populate whatId, otherwise Task will not create
* */
public static void addressUpdationunsucessnotifyByTask(Map<String, Map<Id,String>> accountmanagerids, Map<Id,String> contactIdAccountIdMap ){
// create Task
Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get(System.Label.GeneralTask).getRecordTypeId();
Task addressUpdationFailedTask = new Task();
List<Task> taskList = new List<Task>();
Set<Id> allrecIds = new Set<Id>();
Set<Id> existingTaskWhatIds = new Set<Id>();
for( String objname : accountmanagerids.keySet() ){
for( Id recid : accountmanagerids.get(objname).keySet() ){
allrecIds.add(recid);
}
}
if(!allrecIds.isEmpty()){//***for HRP-9816***Starts here***
for (Task t : [SELECT WhatId FROM Task WHERE Subject IN (:System.Label.InvalidAccountAddressTaskSubject, :System.Label.InvalidContactAddressTaskSubject) AND Status = 'Not Started' AND WhatId IN :allrecIds]){
existingTaskWhatIds.add(t.WhatId);
}
}//***for HRP-9816***ends here***
for( String objname : accountmanagerids.keySet() ){
if(objname == 'Account'){
for( Id recid : accountmanagerids.get(objname).keySet() ){
if(existingTaskWhatIds.isEmpty() || !existingTaskWhatIds.contains(recid)){
system.debug('entered into incorrect address');
addressUpdationFailedTask.RecordTypeId = recTypeId;
addressUpdationFailedTask.ActivityDate = System.today();
addressUpdationFailedTask.OwnerId = accountmanagerids.get(objname).get(recid) ;
addressUpdationFailedTask.subject = System.Label.InvalidAccountAddressTaskSubject;//***for HRP-9816***
addressUpdationFailedTask.WhatId = recid;
taskList.add(addressUpdationFailedTask.clone());
}
}
}else if(objname == 'Contact'){
for( Id recid : accountmanagerids.get(objname).keySet() ){
if(existingTaskWhatIds.isEmpty() || !existingTaskWhatIds.contains(recid)){
addressUpdationFailedTask.RecordTypeId = recTypeId;
addressUpdationFailedTask.ActivityDate = System.today();
addressUpdationFailedTask.OwnerId = accountmanagerids.get(objname).get(recid) ;
addressUpdationFailedTask.subject = System.Label.InvalidContactAddressTaskSubject;//***for HRP-9816***
addressUpdationFailedTask.WhatId = contactIdAccountIdMap.get(recid);
addressUpdationFailedTask.WhoId = recid;
taskList.add(addressUpdationFailedTask.clone());
}
}
}
}
if (taskList.size() > 0) {
insert taskList;
}
}
/* Related to HRP - 8111
* Update the Account Status and Internal Name field on Account based on Record Type
* For Fixed Site Account - Account Status -> Active , Internal Name -> Same as Account Name
* For Mobile Account - Account Status -> Prospect , Internal Name -> Same as Account Name
* This method will work in before insert
* */
public static void updateAccStatusAndInternalName(List<Account> newAccounts)
{
System.debug('Entered method updateAccStatusAndInternalName');
Id fixedAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Fixed Site Account').getRecordTypeId();
Id mobileAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();
for(Account newAccount : newAccounts)
{
if(newAccount.Account_Status__c == null)
{
if(newAccount.RecordTypeId == fixedAccRecTypeId)
{
newAccount.Account_Status__c = 'Active';
}
if(newAccount.RecordTypeId == mobileAccRecTypeId)
{
newAccount.Account_Status__c = 'Prospect';
}
}
if(String.isBlank(newAccount.Internal_Name__c) ==true)
{
newAccount.Internal_Name__c = newAccount.Name;
}
system.debug('Account Status -> '+newAccount.Account_Status__c+' and Internal Name -> '+newAccount.Internal_Name__c);
} // end of for loop
}
/*
* HRP-9585 changes starts here
* @Description: New Accounts autopopulate "ADD" to National Name field.
* @Date: 02/05/2023
*/
public static void updateNationalName(List<Account> newAccounts)
{
if(newAccounts != null){
for(Account acc : newAccounts){
if(String.isBlank(acc.National_Name__c)){
acc.National_Name__c = 'ADD';
}
}
}
}
/*
* HRP-9585 changes Ends
*/
/*
* HRP-9818 changes starts here
* @Description: Check if DRD Users are tring to create Fixed Site Account, then block them.
* @Date: 02/05/2023
*/
public static void checkUserProfile(List<Account> newAccounts)
{
if(newAccounts != null){
Id profileId= userinfo.getProfileId();
List<Profile> pfList = [SELECT Id,Name FROM Profile WHERE Id=:profileId];
String acc_Name = Account.getSObjectType().getDescribe().getName();
RecordType fixedAccRecType = [SELECT Id FROM RecordType WHERE sObjectType=: acc_Name AND Name =: label.Fixed_Site_Account_Record_Type];
List<String> pfNames = label.DRD_User_Profile_Names.split(',');
if(!pfList.isEmpty() && String.isNotBlank(pfList[0].Name) && pfNames.contains(pfList[0].Name)){
for(Account acc : newAccounts){
if(!Test.isRunningTest() && acc.recordTypeId != null && acc.recordTypeId == fixedAccRecType.Id){
acc.addError(label.DRD_Can_t_Create_Fixed_Account_Error_Msg);
}
}
}
}
}
/*
* HRP-9818 changes Ends
*/

//Logic for HRP-10085 for opportunity and Template ***starts here***
public static void updateTemplateBloodDriveOpportunitiesForAccountNameChange(List<Account> accounts,Map<Id, Account> oldAccountMap) {
    Map<Id,Account> nameChangedAccoutMap =new Map<Id,Account>();
    List<Opportunity> oppList = new List<Opportunity>();
    if(accounts == null || oldAccountMap == null || accounts.isEmpty() || oldAccountMap.isEmpty()) {
        return;
    }
    for(Account acc : accounts) {
        if(!oldAccountMap.containsKey(acc.Id) || oldAccountMap.get(acc.Id) == null) {
            continue;
        }
        if((String.isNotBlank(acc.Name) && !acc.Name.equals(oldAccountMap.get(acc.Id).Name))
        ||(String.isNotBlank(acc.Internal_Name__c) && !acc.Internal_Name__c.equals(oldAccountMap.get(acc.Id).Internal_Name__c))) {
            nameChangedAccoutMap.put(acc.Id,acc);
        }
    }
    if(!nameChangedAccoutMap.isEmpty()) {
        oppList = [
            SELECT Id, Name, Drive_Name__c,
            Is_Template__c, accountId,
            Drive_Site__c, Drive_Site_Name__c,
            Account_Internal_Name__c,
            Site_Building_Name__c,
            Template_Status__c, Additional_Description__c
            FROM Opportunity
            WHERE AccountId IN :nameChangedAccoutMap.Keyset()
            AND Is_Template__c = true
        ];
    }

    if(!system.isBatch() && !Test.isRunningTest() && !oppList.isEmpty()) {
        UpdateOpportunityNameBatch batchOppRecs = new UpdateOpportunityNameBatch(oppList, true, true);
        Database.executeBatch(batchOppRecs, 200);
    }
}
//Logic for HRP-10085 for opportunity and Template ***ends here***

public static void updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
    Set<Id> accountIds = new Set<Id>();
    for (Account newAccount : newAccountList) {
        Account oldAccount = oldAccountMap?.get(newAccount.Id);
        if (newAccount.Name != oldAccount?.Name || newAccount.Internal_Name__c != oldAccount?.Internal_Name__c) {
            accountIds.add(newAccount.Id);
        }
    }

    if (!accountIds.isEmpty()) {
        Map<Id, Opportunity> map_oppId_opps = new Map<Id, Opportunity>([
            SELECT Id, Name, AccountId,
            Is_Template__c, Drive_Date__c, 
            Drive_Site__c, Drive_Site_Name__c, Is_Account_Internal_Name_Changed__c,
            Account_Internal_Name__c, RecordTypeId, 
            Linked_Opportunity_Drives__c, Is_this_part_of_MultiDay_Drive__c,
            Site_Building_Name__c, Account.Name, Account_Name__c 
            FROM Opportunity 
            WHERE AccountId IN :accountIds 
            AND Is_Template__c = FALSE
        ]);

        if(!system.isBatch() && !Test.isRunningTest() && map_oppId_opps != null && !map_oppId_opps.isEmpty()) {
            UpdateOpportunityNameBatch batchOppRecs = new UpdateOpportunityNameBatch(map_oppId_opps.values(), false, true);
            Database.executeBatch(batchOppRecs, 1);
        }
    }
}

//Logic for HRP-10085 for Drives on calendar ***starts here***
public static void updateDivesOnCalenderForAccountInternalNameChange(List<Account> accounts, Map<Id, Account> oldAccountMap) {
    Map<Id,Account> nameChangedAccoutMap =new Map<Id,Account>();
    List<Opportunity> OppList = new List<Opportunity>();

    if(accounts == null || oldAccountMap == null || accounts.isEmpty() || oldAccountMap.isEmpty()) return;
    
    for(Account acc : accounts) {
        if(!oldAccountMap.containsKey(acc.Id) || oldAccountMap.get(acc.Id) == null) continue;
    
        if((String.isNotBlank(acc.Name) && !acc.Name.equals(oldAccountMap.get(acc.Id).Name))
        ||(String.isNotBlank(acc.Internal_Name__c) && !acc.Internal_Name__c.equals(oldAccountMap.get(acc.Id).Internal_Name__c))) {
            nameChangedAccoutMap.put(acc.Id,acc);
        }
    }

    List<sked_Drive__c> drivesList = [
        SELECT id, name,
        sked_Account__c, sked_Account__r.name,
        sked_Drive_Site__r.sked_Site_Building_Name__c,
        sked_Drive_Site__r.sked_Room_Name__c,
        sked_Drive_Site__r.Name,
        sked_Account__r.Internal_Name__c
        FROM sked_Drive__c
        WHERE sked_Account__c IN :nameChangedAccoutMap.keyset()
    ];

    for(sked_Drive__c sdc : drivesList) {
        String drivenameNew = '';
        if(sdc.sked_Account__r != null && nameChangedAccoutMap.get(sdc.sked_Account__c) != null) {
            drivenameNew = sdc.sked_Account__r.name + ', ';
            drivenameNew += sdc.sked_Drive_Site__r.Name; //HRP-12136
            sdc.Name = driveNameNew.length() > 80 ? driveNameNew.substring(0, 75) + ' ...' : driveNameNew; //HRP-12136 changed; Prev drivenameNew.length() > 80 ? drivenameNew.substring(0,80) : drivenameNew ;
        }
    }

    if(!drivesList.isEmpty()) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)
        //HRP-12136 start
        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        //HRP-12136 End

        List<Database.SaveResult> updateResults = Database.update(drivesList, false);

        //HRP-12136 start
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        //HRP-12136 End
        
        if(!updateResults.isEmpty()) {
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLogWithObjectId(
                updateResults, 
                'Update DOC Name', 
                'AccountService',
                'updateDivesOnCalenderForAccountInternalNameChange',
                'Error',
                'Update DOC Name'
            );
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
}
//Logic for HRP-10085 for Drives on calendar ***ends here***

/*
* HRP-10878 changes starts here
* @Description: update the filed "Zipcode_change__c" Tracks Old Zipcode value in each update
* @Date: 09/18/2023
*/
public static void setZipcodeChange(List<account> newItems,map<id,Account>oldMap)
{
for(account acc:newItems)
{
if(acc.BillingPostalCode!=null && acc.BillingPostalCode != oldMap.get(acc.id).BillingPostalCode)
{
acc.Zipcode_change__c=oldMap.get(acc.id).BillingPostalCode;
}
else if(acc.ShippingPostalCode!=null && acc.ShippingPostalCode != oldMap.get(acc.id).ShippingPostalCode)
{
acc.Zipcode_change__c=oldMap.get(acc.id).ShippingPostalCode;
}
}
}
//HRP-10878
// HRP-9520 --> Starts Here (New Method Added)
// @Description - System will auto-populate date and user lookup fields with the current date and logged-in user's name whenever user checks the business planning completed checkbox
public static void setBusinessPlanningDateAndUser(List<Account> newAccList, Map<Id,Account> oldAccMap)
{
Set<Id> validAccUpdateIds = new Set<Id>();
List<Account> updateAccountList = new List<Account>();
if(oldAccMap == NULL || newAccList.isEmpty()) {
return;
}
for(Account newAccObj : newAccList) {
Account oldAccObj = oldAccMap.get(newAccObj.Id);
if(oldAccObj!= NULL) {
if(oldAccObj.Business_Planning_Completed__c != newAccObj.Business_Planning_Completed__c && newAccObj.Business_Planning_Completed__c) {
validAccUpdateIds.add(newAccObj.Id);
}
}
}
if(!validAccUpdateIds.isEmpty()) {
Map<Id,Account> updateAccMap = new map<Id,Account>([SELECT Id, Business_Planning_Completed_By__c, Business_Planning_Completed_Date__c FROM Account WHERE ID IN:validAccUpdateIds]);
for(Account updateAcc : updateAccMap.Values()) {
updateAcc.Business_Planning_Completed_Date__c = System.today();
updateAcc.Business_Planning_Completed_By__c = UserInfo.getUserId();
updateAccountList.add(updateAcc);
}
}
if(!updateAccountList.isEmpty()) {
Database.SaveResult[] updateList = Database.update(updateAccountList, FALSE);
List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(updateList, 'Error in updating Business Planning date/completed by field', 'AccountService', 'setBusinessPlanningDateAndUser', 'Error', 'Error during update');
Insert errorLogList;
}
}
// HRP-9520 --> Ends Here

public static void handleTaskPlanningPathChange(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
  Set<Id> changedAccountIds = new Set<Id>();

  for (Account acc : newAccounts) {
    if(acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Fixed Site Account').getRecordTypeId()) continue;
    
    Account oldAcc = oldAccountMap.get(acc.Id);
    
    // Detect if the Planning Path value has changed
    if (acc.Planning_Path__c != oldAcc.Planning_Path__c) {
        changedAccountIds.add(acc.Id);
    }
}

  // Fire the Cascade Batch if changes were detected
if (!changedAccountIds.isEmpty()) {
    Database.executeBatch(new BSF_AccountTaskPlanningCascadeBatch(changedAccountIds), 50);
}
}
}