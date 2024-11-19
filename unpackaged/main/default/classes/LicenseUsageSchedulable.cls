/**
 * Class: LicenseUsageSchedulable
 * Copyright (C) 2024 American Red Cross
 * Purpose: Schedule license usage calculations
 * 
 * Change History:
 * 
 * Developer                Date                Ticket              Description
 * ----------------------------------------------------------------------------------------------------
 * Chris Ferraro            1/15/2024                               Initial creation
 * 
 */

public with sharing class LicenseUsageSchedulable implements Schedulable{
    public void execute(SchedulableContext SC) {
        LicenseUsageHelper.dispatcher();
    }
}