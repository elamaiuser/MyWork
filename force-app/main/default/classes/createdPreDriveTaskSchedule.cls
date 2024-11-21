/* schedulable class to run the createPreDriveTaskBatch 
 * */

global with sharing class createdPreDriveTaskSchedule implements Schedulable{
    global void execute(schedulableContext sc){
        createPreDriveTaskBatch b = new createPreDriveTaskBatch();
        database.executebatch(b);
    }
}