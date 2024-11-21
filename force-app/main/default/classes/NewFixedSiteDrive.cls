public class NewFixedSiteDrive {
    @InvocableMethod(label='CreateFixedSiteDrive' description='Create Drives' category='Opportunity')
    public static void createDrives(List<fixedOpps> opps){
        ID jobID = System.enqueueJob(new NewFixedSiteDriveQueueable(opps));
    }
    public class fixedOpps{
        @InvocableVariable
        public List<Opportunity> oppsToCreate;            
    }
}