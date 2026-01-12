@IsTest
public class BSF_Batch_UpdateTaskType_Test {

    @testSetup
    static void setupData() {

        List<Task> tasks = new List<Task>();

        // Tasks that SHOULD be updated
        tasks.add(new Task(
            Subject = 'Sponsor Planning Meeting',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today()
        ));
        tasks.add(new Task(
            Subject = 'Recruitment Planning Meeting',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today().addDays(1)
        ));

        // Task that should NOT be updated (subject not in map)
        tasks.add(new Task(
            Subject = 'Random Follow Up',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today()
        ));

        // Task that should be excluded by DueDate
        tasks.add(new Task(
            Subject = '72 Hour Check-In',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = System.today().addDays(-5)
        ));

        insert tasks;
    }

    @IsTest
    static void testBatchWithDueDateFilter() {

        // Subject → Type mapping
        Map<String,String> subjectVsType = new Map<String,String>();
        List<Task_Reassignment_Matrix__mdt> taskMatrixList = [SELECT DeveloperName, 
                                                                Task_Type__c,
                                                                Task_Subject__c
                                                                FROM Task_Reassignment_Matrix__mdt 
                                                                WHERE Task_Type__c IN (:BSF_Constants.SPONSOR_PLANNING_MEETING, 
                                                                                    :BSF_Constants.RECRUITMENT_PLANNING_MEETING,
                                                                                    :BSF_Constants.X72_HOUR_CHECK_IN,
                                                                                    :BSF_Constants.SECURITY_INFORMATION_COMPLETION, 
                                                                                    :BSF_Constants.REQUEST_FOR_MARKETING_EXCEPTION,
                                                                                    :BSF_Constants.POST_DRIVE_ANALYSIS_AM,
                                                                                    :BSF_Constants.POST_DRIVE_ANALYSIS_SBPM,
                                                                                    :BSF_Constants.PUBLICITY_ORDER_NOT_CREATED, 
                                                                                    :BSF_Constants.PUBLICITY_REVIEW_NEEDED,
                                                                                    :BSF_Constants.TEMPLATE_ORDER_TASK)
                                                                ];
        for(Task_Reassignment_Matrix__mdt metadata: taskMatrixList){
            subjectVsType.put(metadata.Task_Subject__c,metadata.Task_Type__c);
        }
        // Only pick tasks due from today onwards
        Datetime dueDate = Datetime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0));

        Test.startTest();
            BSF_Batch_UpdateTaskType batch =
                new BSF_Batch_UpdateTaskType(subjectVsType, dueDate);
            Database.executeBatch(batch, 5);
        Test.stopTest();

        // Fetch updated tasks
        Map<String, Task> taskMap = new Map<String, Task>();
        for(Task t : [
            SELECT Id, Subject, Type, ActivityDate
            FROM Task
        ]) {
            taskMap.put(t.Subject, t);
        }

        // Assertions
        System.assertEquals(
            BSF_Constants.RECRUITMENT_PLANNING_MEETING,
            taskMap.get('Recruitment Planning Meeting').Type,
            'Recruitment task should be updated'
        );

        System.assertEquals(
            BSF_Constants.SPONSOR_PLANNING_MEETING,
            taskMap.get('Sponsor Planning Meeting').Type,
            'Sponsor task should be updated'
        );

        // Excluded by due date → should not be updated
        System.assertEquals(
            null,
            taskMap.get('72 Hour Check-In').Type,
            'Past due date task should not be updated'
        );

        // Not in map → should not be updated
        System.assertEquals(
            null,
            taskMap.get('Random Follow Up').Type,
            'Task with unmatched subject should not be updated'
        );
    }

    @IsTest
    static void testBatchWithoutDueDate() {

        Map<String, String> subjectVsType = new Map<String, String>();
        subjectVsType.put('72 Hour Check-In', BSF_Constants.X72_HOUR_CHECK_IN);

        Test.startTest();
            BSF_Batch_UpdateTaskType batch =
                new BSF_Batch_UpdateTaskType(subjectVsType, null);
            Database.executeBatch(batch, 5);
        Test.stopTest();

        Task t = [
            SELECT Type
            FROM Task
            WHERE Subject = '72 Hour Check-In'
            LIMIT 1
        ];

        System.assertEquals(
            BSF_Constants.X72_HOUR_CHECK_IN,
            t.Type,
            'Without due date filter, the task should be updated'
        );
    }
}