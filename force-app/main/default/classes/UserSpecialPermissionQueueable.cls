/**
 * Description: Queueable implementation to execute UserSpecialPermissionService
 * in a separate transaction, ensuring it runs after the main userService wipe.
 */
public class UserSpecialPermissionQueueable implements Queueable {

    private Set<String> userIds;

    public UserSpecialPermissionQueueable(Set<String> userIds) {
        this.userIds = userIds;
    }

    public void execute(QueueableContext context) {
        System.debug(':::TPE::: UserIds: ' + this.userIds);
        UserSpecialPermissionService.assignSpecialPermissions(this.userIds);
    }
}