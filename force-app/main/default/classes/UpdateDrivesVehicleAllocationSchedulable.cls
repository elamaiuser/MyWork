Public class UpdateDrivesVehicleAllocationSchedulable implements Schedulable {
    /*
     * Note : for setting which constructor we need to call. We need to change value of ToHandleConstructorOfUpdateDrivesVehicleAllocationSchedulable custom label and set to 1 or 2 by default it is one
		
        Two Constructor Options:
            For future drives (typeOfDrive as input).
            For a specific date range (fromDate, toDate, and typeOfDrive as inputs).
        Custom Label (ToHandleConstructorOfUpdateDrivesVehicleAllocationSchedulable) determines which constructor to call:
            '1': For future drives.
            '2': For a specific date range.

		Datetime now = Datetime.now().addMinutes(1); // Get the time 1 minute from now
        Integer second = now.second();
        Integer minute = now.minute();
        Integer hour = now.hour();
        
        String cronExp = second + ' ' + minute + ' ' + hour + ' * * ?'; // Repeats daily at the same time
        
        String typeOfDrive = 'Mobile';
        UpdateDrivesVehicleAllocationSchedulable schedulerJob = new UpdateDrivesVehicleAllocationSchedulable(typeOfDrive);
        System.schedule('update Drives Vehicle Allocation for all the future drive', cronExp, schedulerJob);

		To run batch for desired drive date we need to run this:

		Datetime now = Datetime.now().addMinutes(1); // Get the time 1 minute from now
        Integer second = now.second();
        Integer minute = now.minute();
        Integer hour = now.hour();
        
        String cronExp = second + ' ' + minute + ' ' + hour + ' * * ?'; // Repeats daily at the same time

		Date toDate = Date.newInstance(2023,01,30);
    	Date fromDate = Date.newInstance(2023,06,01);
    	String typeOfDrive = 'Mobile';
    
    	UpdateDrivesVehicleAllocationSchedulable schedulerJob = new UpdateDrivesVehicleAllocationSchedulable(toDate, fromDate, typeOfDrive);
        System.schedule('update Drives Vehicle Allocation for custom drive date', cronExp, schedulerJob);
    */
    Date toDate;
    Date fromDate;
    String typeOfDrive;
    String whichconstructorRun = 'first';
    
    Public UpdateDrivesVehicleAllocationSchedulable(String typeOfDrive){
        this.typeOfDrive = typeOfDrive;
        this.whichconstructorRun = 'first';
    }
    
    Public UpdateDrivesVehicleAllocationSchedulable(Date toDate, Date fromDate, String typeOfDrive){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.whichconstructorRun = 'second';
    }
    Public void execute(SchedulableContext SC) {
        
        if (this.whichconstructorRun == 'first') { // this is use to call first constructor of UpdateDrivesVehicleAllocationFieldsBatch
            UpdateDrivesVehicleAllocationFieldsBatch batch1 = new UpdateDrivesVehicleAllocationFieldsBatch(this.typeOfDrive);
            Database.executeBatch(batch1, 100);
            
        } else if (this.whichconstructorRun == 'second') { // this is use to call second constructor of UpdateDrivesVehicleAllocationFieldsBatch
            UpdateDrivesVehicleAllocationFieldsBatch batch2 = new UpdateDrivesVehicleAllocationFieldsBatch(this.toDate, this.fromDate, this.typeOfDrive);
            Database.executeBatch(batch2, 100);
        } else {
            System.debug('Invalid constructor type or none selected.');
        }
    }
    
}