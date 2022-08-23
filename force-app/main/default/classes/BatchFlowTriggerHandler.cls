public with sharing class BatchFlowTriggerHandler extends TriggerHandler {
    protected override void beforeUpdate() {
        processBatchJobsForExecution();
    }
    protected override void beforeInsert() {
        processBatchJobsForExecution();
    }

    private static void processBatchJobsForExecution() {

        List<Batch_Flow__c> executeJobs = new List<Batch_Flow__c>();
        Set<String> updateUnscheduledNextJobIds = new Set<String>();

        for(Batch_Flow__c job : (List<Batch_Flow__c>)Trigger.new) {

            if(Trigger.isUpdate) {

                Batch_Flow__c newJob = (Batch_Flow__c)job;
                Batch_Flow__c oldJob = (Batch_Flow__c)Trigger.oldMap.get(job.Id);

                // Check if jobs are waiting to be executed, if yes then execute jobs
                if(newJob.AsyncApexJobId__c == null &&
                   (newJob.Status__c == 'Queued' && oldJob.Status__c != 'Queued') ||
                   (newJob.Status__c == 'Failed' && oldJob.Status__c != 'Failed')) {

                    executeJobs.add(newJob);
                }

                // check if any scheduled fields have been changed
                // if so then re calculate the next scheduled run date
                if(oldJob.Preferred_Start_Time__c != newJob.Preferred_Start_Time__c ||
                   oldJob.Preferred_Start_Time_Minutes__c != newJob.Preferred_Start_Time_Minutes__c ||
                   oldJob.Day_of_Month__c != newJob.Day_of_Month__c ||
                   oldJob.Run_Units__c != newJob.Run_Units__c) {

                    newJob.Next_Scheduled_Run__c = BatchFlow.GetNextRunTimeForJob(newJob);
                }


                // if Next_Job__c field value is removed then set the 
                // unscheduled checkbox to false on the old next job field value
                //Deprecated
                //if(oldJob.Next_Job__c != null && newJob.Next_Job__c == null) {
                //    updateUnscheduledNextJobIds.add(oldJob.Next_Job__c);
                //}
                

                // if Next_Jobs__c field value is removed then set the 
                // TODO: need to bulkfiy this to evaluate each individual job
                // unscheduled checkbox to false on the old next job field value
                if(oldJob.Next_Jobs__c != null && newJob.Next_Jobs__c == null) {
                    updateUnscheduledNextJobIds.addAll(oldJob.Next_Jobs__c.split(','));
                }
            }
            else if(Trigger.isInsert) {

                Batch_Flow__c newJob = (Batch_Flow__c)job;

                // Set Next Scheduled Run for first time
                newJob.Next_Scheduled_Run__c = BatchFlow.GetNextRunTimeForJob(newJob);
            }
        }

        if(!executeJobs.isEmpty()) {
            BatchFlow.ExecuteJobs(executeJobs);
        }

        if(!updateUnscheduledNextJobIds.isEmpty()) {
            updateUnScheduledJobs(updateUnscheduledNextJobIds);
        }
    }
    // set the unscheduled checkbox to false on the old next job field value
    private static void updateUnScheduledJobs(Set<String> jobIds) {

        List<Batch_Flow__c> updateJobs = new List<Batch_Flow__c>();

        for(Batch_Flow__c job : [SELECT Id, Un_Scheduled__c
                                    FROM Batch_Flow__c
                                    WHERE Id IN :jobIds]) {
            job.Un_Scheduled__c = false;
            updateJobs.add(job);
        }
    
        if(!updateJobs.isEmpty()) {
            update updateJobs;
        }
    }
}