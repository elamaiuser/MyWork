/**
* @description: This class is the controller class for UserCollOppQueueAssigReportVF visualforce page.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 09/17/2024			Barnojit Sharma			Fixed Apex CPU time limit exceeded exception  (HRP-13373)
 *****************************************************************************************************************************************************************************
*/
public without sharing class UserCollOpQueAssngmentReportController {
    
    public  String searchUser{get; set;} // UI user name
    public  String searchCollOpp{get; set;} //UI collection operation name
    public  String errorMsg {get; set;}
    public  boolean errorPresent{get; set;}
    public  List<UserCollOpQueWrapper> UserCollOpQueWrapList {get; set;} // list of report data  wrapper
    public  boolean UserCollOpQueWrapListPresent{get; set;} // boolean set to true if UserCollOpQueWrapList!=null
    public  list<UserCollOpQueQueryWrapper> UserCollOpQueQueryWrapList {get; set;} // list of excel data  wrapper
    
    //constructor
    public UserCollOpQueAssngmentReportController()
    {
        searchUser=null;
        searchCollOpp=null;
        errorPresent=false;
        errorMsg=null;
        UserCollOpQueWrapListPresent = false;
        UserCollOpQueWrapList = new List<UserCollOpQueWrapper>();
        UserCollOpQueWrapList=null;
        UserCollOpQueQueryWrapList = new  list<UserCollOpQueQueryWrapper>();
        UserCollOpQueQueryWrapList=null;
    }
    
    // report data wrapper class
    public class UserCollOpQueWrapper {
        
        public user users {get;set;}
        public groupMember grpMembers {get; set;}
        public group groups {get;set;}
        public integer collOppSize {get;set;}
        public integer queSize {get;set;}
        public string qName {get;set;}
        public Boolean isSelected{get; set;}
        
        public UserCollOpQueWrapper(user u, Integer collSize,Integer qSize,string queueName)
        {   
            users = u;
            collOppSize= collSize;
            queSize = qSize;
            qName = queueName;
            isSelected=false;
        }
    }
    
    // report excel data wrapper class
    public class UserCollOpQueQueryWrapper
    {
        public user selUser {get;set;}
        public groupMember selGrpMembers {get; set;}
        public group selGroups {get;set;}
        public integer selQollOppSize {get;set;}
        public integer selQueSize {get;set;}
        public string selQName {get;set;}
    }
    
    // search method from UI
    public  void search ()
    {
        UserCollOpQueWrapList = new List<UserCollOpQueWrapper>();
        errorPresent=false;
        errorMsg=null;
        string condition;
        
        
        string query='select id,Name,Profile.Name,sked_Collection_Operations__c,UserRoleid  from user where ';
        
        
        if(String.isBlank(searchCollOpp) && String.isBlank(searchUser))
        {
            //system.debug('Here');
            errorMsg='No Input found for Filters';
            errorPresent=true;
        }
        if(String.isNotBlank(searchUser) && searchUser.length() < 3)
        {
            errorMsg='User name must be more than 2 characters';
            errorPresent=true;
        }
        
        if(String.isNotBlank(searchUser) && searchUser.length() >= 3 && String.isBlank(searchCollOpp))
        {
            string s = searchUser;
            condition =  'Name like \'%'+S+'%\'';
        }
        
        if(String.isNotBlank(searchCollOpp) && String.isBlank(searchUser))
        {
            condition = 'sked_Collection_Operations__c includes ('+'\''+searchCollOpp+'\''+')';
        }

        if(String.isNotBlank(searchCollOpp) && searchUser.length() >= 3 && String.isNotBlank(searchUser))
        {
            string s = searchUser;
            condition = 'Name like \'%'+S+'%\' AND sked_Collection_Operations__c includes ('+'\''+searchCollOpp+'\''+')';
        }
        
        if (condition!= null)
        {
            query = query+condition;
        }
        //system.debug('Query'+query);
        
        list<user> userList = new list<user>();
        
        if(!errorPresent && condition!=null)
        {
            userList = Database.query(query,AccessLevel.SYSTEM_MODE);
            if(userList.isEmpty())
            {
                errorMsg='No Records found for the Filters';
                errorPresent=true;
            }
        }
        //commented for HRP-13373
        //('userList'+userList);
        //system.debug('userList'+userList.size());
        
        //map<id,list<id>>userParentRoleID = new map<id,list<id>>();
        /*map<id,id>userRoleID = new map<id,id>();// map user id and UserRoleId
        set<id> userOrg = new set<id>();//set of original users as per the query
        
        for(user u:userList)
        {
            userOrg.add(u.id);
            /*if(!userParentRoleID.keyset().contains(u.UserRoleid))
userParentRoleID.put(u.UserRoleid,new list<id>());

userParentRoleID.get(u.UserRoleid).add(u.id);
            
            userRoleID.put(u.id,u.UserRoleid);
            
        } 
        
        
        list<UserRole> UserRoleList = [SELECT id,ParentRoleId, DeveloperName FROM UserRole];
        
        
        
        list<user> userList1= new list<user>();
        map<id,list<id>> userChildUserMap = new map<id,list<id>>();// map containing both key-user id and value -list of subordinates user id;key-userRoleid and value -list of subordinates userroleid
        for(user u:userList)
        {
            userList1.add(u);
            set<user> temSet = new set<user>();
            temSet.addAll(getRoleSubordinateUsers(u.id));
            userList1.addAll(temSet); // adding subordinates to the list
            
            
            // populating userChildUserMap with user id and subordinates usre id
            list<id> uList =new list<id>();
            for(user u1 :temSet)
            {
                uList.add(u1.id);
            }
            userChildUserMap.put(u.id,uList); 
            
            // populating userChildUserMap with userRole id and subordinates roleIds
            if(!userChildUserMap.keyset().contains(u.UserRoleId))
            {
                userChildUserMap.put(u.UserRoleId,new list<id>());
                userChildUserMap.get(u.UserRoleId).addAll(getAllParentRoleIds(new set<id>{u.UserRoleId}));
            }
            
        }
        
        
        set<user> userSet= new set <user>();
        userSet.addAll(userList1);
        userList1.clear();
        userList1.addAll(userSet);
        
        set<id> userId = new set<id>();// set of all userid(orginal ui as well as subordinates)
        map<id,User> userMap = new map<id,user>(); // map of userid and user
        for(user u:userList1)
        {
            userId.add(u.id);
            userMap.put(u.id,u);
        }
        //system.debug('userId'+userId);
        
        
        if(!errorPresent)
        {
            list<group> groupList = [Select Id, Type, group.name, relatedId, related.name From Group where (type='RoleAndSubordinates' or type='Role')];// grouplist roles and roles and subordionates
            set<id> grpidSet = new set<id>();
            set<id> grpidRoleSubSet = new set<id>();
            map<id,list<id>> groupRelatedIdMap = new map<id,list<id>>();
            for(group grp:groupList)
            {
                
                grpidSet.add(grp.id);
                
                if(grp.type=='RoleAndSubordinates')
                    grpidRoleSubSet.add(grp.id);
                
                if(!groupRelatedIdMap.keyset().contains(grp.RelatedId))
                    groupRelatedIdMap.put(grp.RelatedId,new list<id>());
                groupRelatedIdMap.get(grp.RelatedId).add(grp.id);
            }
            
            
            List<groupMember> pubGrpMemList = [select id,Group.Name,GroupId,Group.type,UserOrGroupId from groupmember where 
                                               (group.type='Regular' Or group.type='Queue' or userorGroupId in:grpidSet) ];//group member list 
            map<string,groupMember> groupIdGrpMemMap = new map<string,groupMember>();  
            map<id,list<string>> UserOrGroupIdMap = new map<id,list<string>>();
            map<id,list<string>> UserOrGroupIdMap2 = new map<id,list<string>>();
            map<string,String> UserOrGroupIdMapMap = new map<string,String>();
            map<id,set<groupMember>> userGroupListMap = new map<id,set<groupMember>>();
            for(groupMember grpMem :pubGrpMemList)
            {
                groupIdGrpMemMap.put(grpMem.GroupId+'_'+grpMem.UserOrGroupId,grpMem);
                if(grpidSet.contains(grpMem.userorGroupId) && grpMem.Group.type=='Queue')
                {
                    //system.debug('inside grpidSet'+grpMem.userorGroupId);
                    if(!userGroupListMap.keyset().contains(grpMem.userorGroupId))
                        userGroupListMap.put(grpMem.UserOrGroupId,new set<groupMember>());
                    
                    userGroupListMap.get(grpMem.UserOrGroupId).add(grpMem);
                }
                
                if(UserOrGroupIdMap.keyset().contains(grpMem.UserOrGroupId))
                {
                    set<string> setDupRemove = new set<string>();
                    setDupRemove.addAll(UserOrGroupIdMap.get(grpMem.UserOrGroupId));
                    setDupRemove.add(grpMem.GroupId+'_'+grpMem.UserOrGroupId);
                    list<string>listforMap = new list<string>();
                    listforMap.addAll(setDupRemove);
                    UserOrGroupIdMap.put(grpMem.UserOrGroupId,listforMap);
                    //UserOrGroupIdMap.get(grpMem.UserOrGroupId).add(grpMem.GroupId+'_'+grpMem.UserOrGroupId);
                    
                }
                else
                {
                    
                    UserOrGroupIdMap.put(grpMem.UserOrGroupId,new list<string>{grpMem.GroupId+'_'+grpMem.UserOrGroupId});
                }
            }
            
            
            
            
            
            
            
            
            
            //iterating over the groupmember records
            for(string grpID:groupIdGrpMemMap.keyset())
            {
                //getting group member record
                groupMember grpMem = groupIdGrpMemMap.get(grpId);
                //Proceed only for user on UserOrGroupId
                if(true)//userId.contains(grpMem.UserOrGroupId))
                {
                    id usersId=grpMem.UserOrGroupId;
                    //if direct queue group
                    if(grpMem.Group.type=='Queue')
                    {
                        //system.debug('Direct Queue Group');
                        if(userGroupListMap.keyset().contains(grpMem.UserOrGroupId))
                        {
                            //system.debug('Entered userGroupListMap if');
                            userGroupListMap.get(usersId).add(grpMem);
                        }
                        else
                        {
                            //system.debug('Entered userGroupListMap else');
                            userGroupListMap.put(usersId,new set<groupMember>{grpMem});
                        }
                        
                    }
                    //system.debug('usersId'+userGroupListMap);
                    //system.debug('not a Direct Queue Group cheking parent group');
                    if(UserOrGroupIdMap.get(grpMem.GroupId)!= null) // map returns parent group id_userID of immediate group of user
                    {
                        //system.debug('grpMem'+grpMem.UserOrGroupId);
                        //system.debug('UserOrGroupIdMap.get(grpMem.GroupId)'+UserOrGroupIdMap.get(grpMem.GroupId));
                        id idVal=grpMem.GroupId;
                        id groupsidPrev;
                        integer i = UserOrGroupIdMap.get(grpMem.GroupId).size();
                        //for(string groupsid:UserOrGroupIdMap.get(grpMem.GroupId))
                        {
                            
                            //system.debug('outseide while'+idVal);
                            //system.debug('outseide while'+groupsidPrev);
                            while(groupsidPrev!=idVal)//(
                            {
                                
                                if(UserOrGroupIdMap.get(idVal)!=null )
                                {
                                    //system.debug('UserOrGroupIdMap.get(idVal)'+UserOrGroupIdMap.get(idVal));
                                    for(string groupsids:UserOrGroupIdMap.get(idVal))
                                    {
                                        groupsidPrev=idVal;
                                        //system.debug('outseide while'+groupsidPrev);
                                        groupMember grpMemofGrp = groupIdGrpMemMap.get(groupsids); //groupid_userId returns groupmember 
                                        //system.debug('grpMemofGrp'+grpMemofGrp);
                                        if(grpMemofGrp.Group.type=='Queue')
                                        {
                                            //system.debug('not a Direct Queue Group but parent group queue');
                                            if(userGroupListMap.keyset().contains(usersId))
                                            {
                                                userGroupListMap.get(usersId).add(grpMemofGrp);
                                                //system.debug('Entered group check'+' Entered userGroupListMap if'+userGroupListMap);
                                            }
                                            else
                                            {
                                                userGroupListMap.put(usersId,new set<groupMember>{grpMemofGrp});
                                                //system.debug('Entered group check'+' Entered userGroupListMap else'+userGroupListMap);
                                            }
                                            //system.debug('grpMemofGrp.GroupId'+grpMemofGrp.GroupId);
                                        }
                                        else
                                        {
                                            //system.debug('//////beforechange'+idVal);
                                            list<string> parentgroup =UserOrGroupIdMap.get(grpMemofGrp.GroupId);
                                            if(parentgroup!=null)
                                            {
                                                UserOrGroupIdMap.get(idVal).addAll(parentgroup);
                                            }
                                            else
                                            {
                                                idVal = grpMemofGrp.GroupId;
                                            }
                                            
                                            //system.debug('//////afterchange'+idVal);
                                            //system.debug('/////groupsidPrev'+groupsidPrev);
                                            //setting the parent groupid
                                            
                                            
                                        }
                                    }
                                }
                                
                                else
                                {
                                    idVal=groupsidPrev;
                                }
                                
                            }
                        }
                    }
                    
                }
                
            }
            
            
            system.debug('userGroupListMap'+userGroupListMap);
            if(userGroupListMap!=null)
            {
                
                //adds queue access because of subordinates user queue
                for(id parentid :userChildUserMap.keyset())
                {
                    if(userOrg.contains(parentid))
                    {
                        
                        for(id childID : userChildUserMap.get(parentid))
                        {
                            
                            if(userGroupListMap.keyset().contains(childID))
                            {
                                if(userGroupListMap.keyset().contains(parentid))
                                {
                                    userGroupListMap.get(parentid).addAll(userGroupListMap.get(childID));
                                }
                                else
                                {
                                    userGroupListMap.put(parentid,userGroupListMap.get(childID));
                                }
                            }
                        }
                    }
                }
                
                //adds role and subordinate queue
                for(id usersid : userGroupListMap.keyset())
                {
                    if(userChildUserMap.keyset().contains(userRoleID.get(usersid)))
                    {
                        //system.debug('has parent role'+userChildUserMap.get(userRoleID.get(usersid)));
                        for(id roleId : userChildUserMap.get(userRoleID.get(usersid)))
                        {
                            if(groupRelatedIdMap.keyset().contains(roleId))
                            {
                                for(id bggroupid:groupRelatedIdMap.get(roleId))
                                {
                                    //system.debug('bggroupid'+bggroupid);
                                    if(userGroupListMap.keyset().contains(bggroupid))
                                    {
                                        userGroupListMap.get(usersid).addAll(userGroupListMap.get(bggroupid));
                                    }
                                }
                            }
                        }
                    }
                }
                
                //adds role queues
                for(id usersid : userGroupListMap.keyset())
                {
                    if(userGroupListMap.keyset().contains(userRoleID.get(usersid)))
                    {
                        userGroupListMap.get(usersid).addAll(userGroupListMap.get(userRoleID.get(usersid)));
                    }
                }
                
                // Finalised queue passed to vf page
                for(id usersid : userOrg)
                {
                    integer collOppSize;
                    integer queueSize;
                    String queueNames ;
                    list<string> queueNamesList = new list<string>();
                    list<string> collstring = new list<string>();
                    if(userGroupListMap != null && userGroupListMap.get(usersid)!=null)
                    {
                        
                        //system.debug('userGroupListMap.get(usersid)'+userGroupListMap.get(usersid).size());
                        for(groupMember grpMem :userGroupListMap.get(usersid))
                        {
                            if(queueNames==null)
                            {
                                queueNames =grpMem.group.Name;
                                queueNamesList.add(grpMem.group.Name);
                            }
                            else if(!queueNamesList.contains(grpMem.group.Name))
                            {
                                queueNamesList.add(grpMem.group.Name);
                                queueNames=queueNames+','+grpMem.group.Name;
                                
                            }
                        }
                        queueSize=queueNamesList.size();
                        
                        
                        
                    }
                    else
                    {
                        //queueNames='-';
                        queueSize=0;
                    }
                    
                    if(userMap.get(usersid).sked_Collection_Operations__c!=null)
                    {
                        collstring  =userMap.get(usersid).sked_Collection_Operations__c.split(';');
                    }
                    collOppSize = collstring.size();
                    //('collOppSize'+collOppSize);
                    if(userMap.get(usersid).sked_Collection_Operations__c!=null || queueSize!=0)
                    {
                    UserCollOpQueWrapList.add(new UserCollOpQueWrapper(userMap.get(usersid),collOppSize,queueSize,queueNames));
                        UserCollOpQueWrapListPresent=true;
                    }
                }
                //system.debug(UserCollOpQueWrapList);*/
        /*
        * HRP-13373 changes starts here
        */
        if(!userList.isEmpty()){
            UserCollOpQueWrapList = getUserWrapper(userList);
            UserCollOpQueWrapListPresent = true;
        }
        /*
        * HRP-13373 changes ends here
        */

        if(!errorPresent && UserCollOpQueWrapList.isEmpty())
        {
            UserCollOpQueWrapListPresent=false;
            errorMsg='The selected User doesn\'t have any Queue/Collection Operation assignment to them';
            errorPresent=true;
        }
    }
    
    
    
    public void selectedRecords(){       
        UserCollOpQueQueryWrapList = new  list<UserCollOpQueQueryWrapper>();  
        list<user> selectedUserList = new list<user>();
        if(UserCollOpQueWrapList != null){
            for(UserCollOpQueWrapper wrapData : UserCollOpQueWrapList){
                
                
                if(wrapData.isSelected == true)
                {
                    //system.debug('HErew');
                    UserCollOpQueQueryWrapper WrapperObj = new UserCollOpQueQueryWrapper();
                    WrapperObj.selUser = wrapData.users; 
                    WrapperObj.selGrpMembers=wrapData.grpMembers;
                    WrapperObj.selGroups = wrapData.groups;
                    WrapperObj.selQollOppSize = wrapData.collOppSize;
                    WrapperObj.selQueSize = wrapData.queSize;
                    WrapperObj.selQName = wrapData.qName;
                    //system.debug('WrapperObj'+WrapperObj);
                    UserCollOpQueQueryWrapList.add(WrapperObj);
                }  
            }     
           // system.debug('UserCollOpQueQueryWrapList'+UserCollOpQueQueryWrapList);
        }
    }
    
    public PageReference ExportToExcel() {
        selectedRecords();               
        return page.UserCollOppQueueAssignExcelVF;
    }
    
    public void clear(){
        
        UserCollOpQueWrapList = null;
        UserCollOpQueQueryWrapList = null;
        searchUser=Null;
        searchCollOpp=null;
        
        errorPresent=false;
        UserCollOpQueWrapListPresent=false;
    }
    
    
    public static Set<user> getRoleSubordinateUsers(Id userId) {
        
        //Get requested user's role Id
        Id roleId = [SELECT UserRoleId From User Where Id = :userId].UserRoleId;
        //Get all of the roles below the user
        Set<Id> allSubRoleIds = getAllSubRoleIds(New Set<ID>{roleId});
        // get all of the ids for the users in those roles
        Map<Id, User> users = new Map<Id, User>([SELECT Id, Name From User Where UserRoleId IN :allSubRoleIds]);
        //Return the ids as a set
        Set<user> userSet= new set<user>();
        userSet.addAll(users.values());
        return userSet;
    }
    
    
    private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        //Get all of the roles below the passed roles
        for(UserRole userRole :[SELECT Id from UserRole Where ParentRoleId IN :roleIds AND ParentRoleID != null]){
            currentRoleIds.add(userRole.Id);
        }
        
        //Fetch more roles
        if(currentRoleIds.size() > 0){
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }        
        return currentRoleIds;   
    }
    
    //Get all Parent Roles.
    private static Set<ID> getAllParentRoleIds(Set<ID> roleIds) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        //Get all of the roles above the passed roles
        for(UserRole userRole :[SELECT Id,ParentRoleId from UserRole Where Id IN :roleIds AND ParentRoleID != null]){
            currentRoleIds.add(userRole.ParentRoleId);
        }
        
        //Fetch more rolls
        if(currentRoleIds.size() > 0){
            currentRoleIds.addAll(getAllParentRoleIds(currentRoleIds));
        }        
        
        return currentRoleIds;   
    }

    /*
    * HRP-13373 changes starts here
    */
    /*
    *********************************************************
    @Method Name    : getAllParentQueueNames
    @author         : Barnojit Sharma
    @description    : method to get the parent queue names.
    ********************************************************
    */
    public Map<Id,String> getAllParentQueueNames(Id groupId,Map<Id, List<Id>> groupParentMap, Map<Id,String> queueNameMap, Map<Id,String> queueNames){
        if(queueNameMap.containsKey(groupId)){
            queueNames.put(groupId,queueNameMap.get(groupId));
        }
        if(groupParentMap.containsKey(groupId)){
            for(Id parentId : groupParentMap.get(groupId)){
                queueNames.putAll(getAllParentQueueNames(parentId,groupParentMap,queueNameMap,queueNames));
            }
        }
        return queueNames;
    }
    /*
    *********************************************************
    @Method Name    : getUserWrapper
    @author         : Barnojit Sharma
    @description    : method to get the VF wrapper from user data.
    ********************************************************
    */
    public List<UserCollOpQueWrapper> getUserWrapper(List<User> userList){
        List<UserCollOpQueWrapper> userCollOpQueWrapList = new List<UserCollOpQueWrapper>();
        String usrIdPrefix = User.sObjectType.getDescribe().getKeyPrefix();
        Map<Id, User> userMap = new Map<Id, User>(userList);
        Map<Id,List<Id>> groupParentMap = new Map<Id,List<Id>>();
        Map<Id,List<Id>> userGroupMap = new Map<Id,List<Id>>();
        Map<Id,String> queueNameMap = new Map<Id,String>();
        List<GroupMember> usrGrpMemList = [SELECT Id,
                                                GroupId,
                                                Group.Type,
                                                Group.Name,
                                                UserOrGroupId 
                                            FROM GroupMember 
                                            WHERE Group.Type IN ('Regular','Queue')
                                            AND UserOrGroupId != null
                                          	WITH SYSTEM_MODE];
        for(GroupMember usrGrpMem : usrGrpMemList){
            if(usrGrpMem.Group.Type.equals('Queue')){
                queueNameMap.put(usrGrpMem.GroupId,usrGrpMem.Group.Name);
            }
            if(!String.valueOf(usrGrpMem.UserOrGroupId).left(3).equals(usrIdPrefix)){
                if(!groupParentMap.containsKey(usrGrpMem.UserOrGroupId)){
                    groupParentMap.put(usrGrpMem.UserOrGroupId, new List<Id>());
                }
                groupParentMap.get(usrGrpMem.UserOrGroupId).add(usrGrpMem.GroupId);
            } else if(userMap.keySet().contains(usrGrpMem.UserOrGroupId)){
                if(!userGroupMap.containsKey(usrGrpMem.UserOrGroupId)){
                    userGroupMap.put(usrGrpMem.UserOrGroupId, new List<Id>());
                }
                userGroupMap.get(usrGrpMem.UserOrGroupId).add(usrGrpMem.GroupId);
            }
        }
        for(Id userId : userMap.keySet()){
            Integer collOppSize = 0;
            Map<Id,String> queueNames = new Map<Id,String>();
            if(userMap.get(userId).sked_Collection_Operations__c != null){
                collOppSize = userMap.get(userId).sked_Collection_Operations__c.split(';').size();
            }
            if(userGroupMap.containsKey(userId)){
                for(Id groupId : userGroupMap.get(userId)){
                    queueNames.putAll(getAllParentQueueNames(groupId,groupParentMap,queueNameMap,queueNames));
                }
            }
            userCollOpQueWrapList.add(new UserCollOpQueWrapper(userMap.get(userId),collOppSize,queueNames.size(),String.join(queueNames.values(),', ')));
        }
        return userCollOpQueWrapList;
    }
    /*
    * HRP-13373 changes ends here
    */
}