global class PostSandBoxRefresh implements SandboxPostCopy{
    
    global void runApexClass(SandboxContext context) {
        System.debug('Org ID: ' + context.organizationId());
        System.debug('Sandbox ID: ' + context.sandboxId());
        System.debug('Sandbox Name: ' + context.sandboxName());
		List<User> userList =[select username, email from user where username like '%anil.kallu@redcross.org%'];
        for(User u:userList){
            u.email = 'anil.kallu@redcross.org';
        }
        update userList;
        // Insert logic here to prepare the sandbox for use.
    }

}