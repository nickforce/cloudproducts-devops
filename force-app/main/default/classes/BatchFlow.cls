global class BatchFlow implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    // query Active jobs in BatchFlow table
    global final String query = 'SELECT Id, Name, Day_of_Month__c, ' + 
                                    'Next_Jobs__c, Dependent_Jobs__c, Multiple_Dependency__c, ' +
                                    'Active__c, Apex_Class__c, Status__c, ' + 
                                    'StartTime__c, EndTime__c, Next_Job__c, ' +
                                    'Next_Scheduled_Run__c, Scope_Size__c, ' + 
                                    'Exception__c, AsyncApexJobId__c, ' + 
                                    'Un_Scheduled__c, Run_Units__c, ' +
                                    'Run_Increment__c, Preferred_Start_Time__c, ' + 
                                    'Preferred_Start_Time_Minutes__c, ' + 
                                    'ActivateNumberOfErrors__c, NumberOfErrors__c, ' +
                                    'Emails__c, Send_Job_Summary__c, ' +
                                    'Job_Summary_Email_Subject__c ' +
                                 'FROM Batch_Flow__c ' +
                                 'WHERE Active__c = TRUE';
    
    
    // used to abort current daemon job prior to rescheduling another daemon X minutes in the future
    private Id daemonJobId; // id of current daemon config job
    private List<Batch_Flow__c> updateJobs = new List<Batch_Flow__c>();

    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // "Config" job will run every X minutes initiallizing this batch, 
        // always aborting itself and rescheduling X minutes in the future
        // monitoring "Daemon" immiation job
        // 
        // executing jobs is currentlyl done by a BatchFlow trigger
        return Database.getQueryLocator(query);
    }
    
    public BatchFlow() {}

    // Execute
    global void execute(Database.Batchablecontext BC, List<SObject> scope) {
        Set<Id> classIds = getExecutingApexClassIds();
        Map<String,ApexClass> runningClassesByName = getRunningClassesByName(classIds);
        List<Batch_Flow__c> jobs = (List<Batch_Flow__c>)scope;
        Map<Id, Batch_Flow__c> jobMap = new Map<Id, Batch_Flow__c>((List<Batch_Flow__c>)scope);
        // Check to see if they're still running, completed or failed.
        Map<String, Batch_Flow__c> startedJobsByAsyncApexJobId = new Map<String, Batch_Flow__c>();

        // process custom job table records
        for(Batch_Flow__c job : jobs) {
            // Check to see if they're still running, completed or failed.
            if(job.StartTime__c != null &&
               job.EndTime__c == null &&
               job.AsyncApexJobId__c != null &&
               job.Status__c == 'Started') {
                startedJobsByAsyncApexJobId.put(job.AsyncApexJobId__c, job);
            }

            // If the Next Run time is less than now, then this job is ready to be run
            // Status should not be Queued already as this flag is used in trigger for execution
            // Job should not be Un Scheduled as well.. meaning it is either the beginning
            // of a chain or a single job scheduled
            // Also check if job is already queued to run or currently running
            // PURPOSE: QUEUE up Individual Jobs or Leader of Chain Jobs
            if(job.Next_Scheduled_Run__c <= Datetime.now() &&
               !runningClassesByName.containsKey(job.Apex_Class__c) &&
               job.AsyncApexJobId__c == null &&
               job.Status__c != 'Queued' &&
               !job.Un_Scheduled__c) {

                 // add job to list for update/execute
                job.Status__c = 'Queued';

                updateJobs.add(job);
            }
        } // end of scanning custom job table

        if(startedJobsByAsyncApexJobId.isEmpty()) return;
        
        // next scan system job table to match against active jobs in the custom table
        List<Batch_Flow__c> matchingJobs = new List<Batch_Flow__c>();
        Map<Id, AsyncApexJob> jobIdByAsyncApexJob = new Map<Id, AsyncApexJob>();
        for(AsyncApexJob batchJob : [SELECT Status, ExtendedStatus, NumberOfErrors, TotalJobItems
                                        FROM AsyncApexJob
                                        WHERE Id IN :startedJobsByAsyncApexJobId.keyset()
                                        AND Status IN ('Failed', 'Aborted', 'Completed')]) {
            Batch_Flow__c thisJob;
            if(startedJobsByAsyncApexJobId.get(batchJob.Id) == null) {
                // todo uniform it to 1 length ids across app.. wtf is this
                thisJob = startedJobsByAsyncApexJobId.get(String.valueOf(batchJob.Id).substring(0,15));
            }
            else {
                thisJob = startedJobsByAsyncApexJobId.get(batchJob.Id);
            }
            matchingJobs.add(thisJob);
            jobIdByAsyncApexJob.put(thisJob.Id, batchJob);
        }

        if(matchingJobs.isEmpty()) return;

        for(Batch_Flow__c job : matchingJobs) {
            AsyncApexJob batchJob = jobIdByAsyncApexJob.get(job.Id);
            // When a Job fails .. //Failed,Aborted
            if(batchJob.Status != 'Completed') {
                job.Status__c = 'Failed';
                job.AsyncApexJobId__c = null;
                job.Exception__c = batchJob.ExtendedStatus;
                // send email for job Failed
                sendEmailOnFailures(job, true);
                updateJobs.add(job);
            }
            
            // When a Job Completes .. 
            if(batchJob.Status == 'Completed' && !job.ActivateNumberOfErrors__c) {
                // Calculate Next Run if UnScheduled = false
                // Check "Next Job" field for a chained job.. send through trigger to execute if it finds one
                job.Status__c = 'Completed';
                job.AsyncApexJobId__c = null;
                job.EndTime__c = DateTime.now();

                if(job.Send_Job_Summary__c && batchJob.NumberOfErrors == 0) {
                    sendJobSummaryEmail(batchJob, job);
                }
                
                // check if job is completed with errors
                if(batchJob.NumberOfErrors > 0) {
                    job.Exception__c = batchJob.ExtendedStatus;
                    sendEmailOnFailuresWithErrors(job, false, batchJob.NumberOfErrors);
                }

                // check if first job in chain of jobs 
                // if yes then set a Next Run Date, if not 
                // then the next job will kickoff as normal
                if(!job.Un_Scheduled__c) {
                    job.Next_Scheduled_Run__c = GetNextRunTimeForJob(job);
                }
                // Individual Job to update, not linked to a chain
                updateJobs.add(job);

                // - Multiple Job Chaining, includuing 1 to 1, 2 to 1 to 3, etc
                // .. dependent job chains, async job chains
                // Check for the next jobs
                // ... Loop thru each job if ready to launch
                // .. Multiple_Dependency__c, Next_Jobs__c, Dependent_Jobs__c
                // ... Mark as Queued to run job
                // Next Jobs >> if job Next Jobs != null  (comma separated list Ids)
                // TODO: requery for full job map (or something, scope of batch Flow potential to not include all jobs)
                if(job.Next_Jobs__c != null) {   
                    // TODO: Test this with 1 job and multiple as next job
                    for(String s : job.Next_Jobs__c.split(',')) {
                        // Check for dependencies before setting status to queued
                        // s is one job
                        Batch_Flow__c nextJob = jobMap.get(s);
                        if(nextJob == null) {
                            nextJob = jobMap.get(String.valueOf(s).substring(0,15)); 
                        }

                        if(nextJob != null) {
                            // Determine if Dependent jobs have completed
                            if(nextJob.Multiple_Dependency__c) {
                                if(validDependencies(nextJob.Dependent_Jobs__c, jobMap)) {
                                    nextJob.Status__c = 'Queued';
                                    updateJobs.add(nextJob);
                                }
                            }    
                            else { // no dependencies, setup next job to run as scheduled
                                nextJob.Status__c = 'Queued';
                                updateJobs.add(nextJob);
                            }
                        }
                    }  
                }
                
                // - Single Job chaining 1 to 1
                // check for Next Job in chain
                // if Next Job populate then set Status to Queued to 
                // send to BatchFlow trigger for execution
                // if(job.Next_Job__c != null) {

                //     Batch_Flow__c nextJob = jobMap.get(job.Next_Job__c);
                //     if(nextJob == null) {
                //         nextJob = jobMap.get(String.valueOf(job.Next_Job__c).substring(0,15)); 
                //     }
                //     if(nextJob != null) {
                //         nextJob.Status__c = 'Queued';
                //         updateJobs.add(nextJob);
                //     }
                // }
            }

            // --Activate Completed w/ Number Of Errors Allowed feature--
            // todo, set max number of retries(2)
            if(batchJob.Status == 'Completed' && job.ActivateNumberOfErrors__c) {
                if(batchJob.NumberOfErrors > 0 && 
                   batchJob.NumberOfErrors > job.NumberOfErrors__c) {
                        job.Status__c = 'Failed';
                        job.AsyncApexJobId__c = null;
                        job.Exception__c = batchJob.ExtendedStatus;
                        // send email for job completed with failures and now attempting to rerun
                        sendEmailOnFailuresWithErrors(job, false, batchJob.NumberOfErrors);
                        updateJobs.add(job);
                }
            }  
        }
    }

    // Finish
    global void finish(Database.Batchablecontext BC) {
        // Perform update on modified job records in order to call
        // out the Batch Flow trigger to manage chain orders 
        // and handle execution of jobs as well as re running failed jobs
        if(!updateJobs.isEmpty()) {
            try {
                Database.update(updateJobs,false);
            }
            catch(Exception ex) {
                SendEmailOnException(ex, 'Could not update jobs', UserInfo.getUserEmail());
            }
        }
        // Abort the "Config" Batch Flow Scheduler Cron Job
        if(daemonJobId != null) {
            System.abortjob(daemonJobId);
        }

        // on/off switch here to start/stop batch job monitoring
        // Setup scheduling for on/off
        if(BatchFlow_Config__c.getall().get('Config').Monitor_Jobs__c) {
            // Object declared to invoke a new schedule
            BatchFlow theJobScheduler = new BatchFlow();

            //Get the system date and time.
            Datetime dt = DateTime.now();
            // Interval of 2 minutes after processing of first job. It can be set in terms of seconds also.
            // Store interval in a custom setting..
            dt = dt.addMinutes(Integer.valueof(BatchFlow_Config__c.getall().get('Config').Frequency__c));     
            String sch = String.valueOf( dt.second() ) + ' ' + String.valueOf( dt.minute()   ) + ' ' + String.valueOf( dt.hour() ) + ' '  + String.valueOf( dt.day() ) +  ' ' + String.valueOf( dt.month() ) + ' '  + '? ' + String.valueOf( dt.Year());
            
            // store the cron job Id to be used for aborting
            // Run schedule job with a TimeStamp. 
            BatchFlow_Config__c settings = BatchFlow_Config__c.getall().get('Config');
            settings.Job_Id__c = system.schedule('Batch Flow Apex Job Scheduler '+ String.valueof(dt),sch,theJobScheduler);
            update settings;
        }
    }

    
    // Schedulable interface 
    global void execute(SchedulableContext ctx){ 
        try {
            BatchFlow batchMgr = new BatchFlow();
            //Schedule Class trigger id is stored in order to abort it before the start of next Schedule Class
            batchMgr.daemonJobId = ctx.getTriggerId();
            //store the cron job Id to be used for aborting from the UI
            BatchFlow_Config__c settings = BatchFlow_Config__c.getall().get('Config');
            settings.Job_Id__c = ctx.getTriggerId();
            update settings;
            
            // run job
            database.executebatch(batchMgr);
        }
        catch(Exception ex) {
            SendEmailOnException(ex, 'Could not schedule job', UserInfo.getUserEmail());
        }
    }

    /* Exceptions */

    public class BatchFlowException extends Exception{}

    /* Utils */

    private Map<String,ApexClass> getRunningClassesByName(Set<Id> classIds) {
        // Get the Names of any ApexClasses corresponding to these ApexClassIds
        Map<String,ApexClass> runningClassesByName = new Map<String,ApexClass>();
        for (ApexClass c : [SELECT Name, NamespacePrefix 
                            FROM ApexClass 
                            WHERE Id in :classIds]) {

            runningClassesByName.put(((c.NamespacePrefix != null) ? c.NamespacePrefix + '.' : '') + c.Name,c);
        }

        return runningClassesByName;
    }

    private Set<Id> getExecutingApexClassIds() {
        Set<Id> classIds = new Set<Id>();
        // Get the ApexClass Ids of any currently executing Batch Apex classes
        for(AsyncApexJob job : [SELECT ApexClassId 
                                FROM AsyncApexJob
                                WHERE Status IN ('Queued','Processing','Preparing','Holding')]) {

            classIds.add(job.ApexClassId);
        } 
        return classIds;
    }

    public static void ExecuteJobs(List<Batch_Flow__c> jobs) {
        // (Called from the Batch_Flow__c  before context trigger)
        // Attempt to execute a new Apex Job
        // corresponding to each of the Batch_Flow__c records
        // execute job with scope and parameters if available
        for(Batch_Flow__c job : jobs) {
            // Check if this Job's Apex Class name is valid
            System.Type t = GetTypeForClassName(job.Apex_Class__c);

            // Try to execute the job
            try {
                // check for scope size to limit the batch size
                if(job.Scope_Size__c != null && job.Scope_Size__c > 0) {
                    
                    job.AsyncApexJobId__c = Database.executebatch((Database.Batchable<sObject>)JSON.deserialize('{}',t), integer.valueOf(job.Scope_Size__c));
                }
                else {
                    job.AsyncApexJobId__c = Database.executebatch((Database.Batchable<sObject>)JSON.deserialize('{}',t));   
                }
            }
            catch(Exception ex) {
                SendEmailOnException(ex, 'Could not execute job', UserInfo.getUserEmail());
            }

            job.Status__c = 'Started';
            job.StartTime__c = Datetime.now();
            job.EndTime__c = null;
        }
    } 
    
    public static boolean validDependencies(String dependentJobIds, Map<Id, Batch_Flow__c> jobMap) {
        // Determine if Dependent jobs have completed
        for(String s : dependentJobIds.split(',')) {
            Batch_Flow__c nextJob = jobMap.get(s);
            if(nextJob == null) {
                nextJob = jobMap.get(String.valueOf(s).substring(0,15)); 
            }
            if(nextJob != null) {
                if(nextJob.Status__c != 'Completed') {
                    return false;
                }         
            }
        }

        return true;
    }
    
    public static System.Type GetTypeForClassName(String name) {
        // Get the System.Type for a string representation of an Apex Class name
        // such as 'namespace.MyClassName.MyInnerClassName'
        System.Type t;
        
        // Try all sorts of permutations and send a debug email with them
        t = System.Type.forName(name);
        
        if((t == null) && (!name.contains('.'))) {
            t = System.Type.forName(null,name);
        }    
        
        if((t == null) && (name.indexOf('.')!=-1)){
            String sansNamespace = name.substring(name.indexOf('.')+1);
            t = System.Type.forName(sansNamespace);
        }
        
        return t;
    }


    /* Crons */

    public static Datetime GetNextRunTimeForJob(Batch_Flow__c job) {
        // Get the next time that a Job should be run,
        // starting with the last time that the Job was run(StartTime),
        // or starting NOW if their is no StartTime
        return GetNextRunTimeForJob(job, ((job.StartTime__c == null) ? Datetime.now() : job.StartTime__c));
    }

    public static Datetime GetNextRunTimeForJob(Batch_Flow__c job, Datetime start) {
        // Calculate the next time that a Job should be run,
        // relative to a given starting point.
        // Run Units and Run Increment must be non-null
        // Preferred Start Time (Hour 0-23) must be non-null
        Datetime nextRun = null;
        if(job.Run_Units__c != null && job.Run_Increment__c != null && job.Run_Increment__c >= 1 && job.Preferred_Start_Time__c != null) {
            Integer increment = Integer.valueOf(job.Run_Increment__c);
            Integer prefStartTimeHour = Integer.valueOf(job.Preferred_Start_Time__c);
            Integer prefStartTimeMinutes = Integer.valueOf(job.Preferred_Start_Time_Minutes__c);
            
            if(job.Run_Units__c == 'Minutes') {
                nextRun = start.addMinutes(increment);
            }
            else if(job.Run_Units__c == 'Hours') {
                nextRun = start.addHours(increment);
            }
            else if(job.Run_Units__c == 'Days') {

                nextRun = DateTime.newInstance(start.year(), start.month(), start.day(), prefStartTimeHour, prefStartTimeMinutes, 0);

                // check if next run should be same day
                // usually true when job is first scheduled
                // else iterate to the next day
                if(nextRun <= start) {
                    nextRun = nextRun.addDays(increment);
                }
                
            }
            else if(job.Run_Units__c == 'Weeks') { 
                nextRun = start.addDays(increment * 7);
            }
            else if(job.Run_Units__c == 'Months') {
                
                Integer dayOfMonth;

                // check if "last" day of month selected
                if(job.Day_of_Month__c == 'last') {
                    // check if today is the last day of the month
                    // if so then iterate to the next month
                    if(Date.daysInMonth(start.year(), start.month()) == start.day()) {
                       
                       dayOfMonth = Date.daysInMonth(start.year(), start.month() + 1);   

                       nextRun = DateTime.newInstance(start.year(), start.month() + 1, dayOfMonth, prefStartTimeHour, prefStartTimeMinutes, 0);
                    }
                    else {
                       dayOfMonth = Date.daysInMonth(start.year(), start.month());       

                       nextRun = DateTime.newInstance(start.year(), start.month(), dayOfMonth, prefStartTimeHour, prefStartTimeMinutes, 0);
                    }
                }
                else {
                    dayOfMonth = Integer.valueOf(job.Day_of_Month__c);

                    // if day of month to run is in future then set to current month
                    // else iterate to next month
                    if(dayOfMonth > start.day()) {
                        nextRun = DateTime.newInstance(start.year(), start.month(), dayOfMonth, prefStartTimeHour, prefStartTimeMinutes, 0);
                    }
                    else { 
                        nextRun = DateTime.newInstance(start.year(), start.month() + 1, dayOfMonth, prefStartTimeHour, prefStartTimeMinutes, 0);
                    }
                }
            }
            /*
            if(job.Run_Units__c == 'Weeks') {

                Map<String, Integer> weeklyMap = new Map<String, Integer>();

                if(job.Sunday__c) {
                    weeklyMap.put('Sunday', 1);
                }
                if(job.Monday__c) {

                }
            }
            else if(job.Run_Units__c == 'Months') nextRun = start.addMonths(increment);
            */
        }
        return nextRun;
    }

    /* Emails */

    public static void SendJobEmail(String htmlBody, String textBody, String subject, String jobEmails) {
        // Send an email to the specified email addresses with a report of how the batch job went
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        List<String> emailStrings = new List<String>();
        //add emails from email field
        emailStrings = jobEmails.split(',');
        //add emails from custom setting
        //Set<String> emails = Batch_Flow_Emails__c.getAll().keyset();
        //emailStrings.addAll(emails);

        mail.setToAddresses(emailStrings);
        mail.setReplyTo('nick@sansotti.com');
        mail.setSenderDisplayName('Batch Flow');
        mail.setSubject(subject);
        mail.setPlainTextBody(textBody);
        mail.setHtmlBody(htmlBody);
        
        //Messaging.reserveSingleEmailCapacity(1);
        
        List<Messaging.SendEmailResult> result = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{mail}
        );
    }
    public static void sendEmailOnFailures(Batch_Flow__c job, Boolean retryJob) {    

        String htmlBody = '';
        String plainTextBody = '';
        String subject = 'Batch Flow Job(' + job.Name + ' - ' + job.Apex_Class__c + ') Failed';

        if(retryJob) {

            htmlBody = 'Batch Flow is now attempting to re run this job.<br/><br/>';
            plainTextBody = 'Batch Flow is now attempting to re run this job.\n\n';
        }

        htmlBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '<br/>'
                + 'Status Detail: ' + job.Exception__c + '<br/>' 
                + 'Job Id: ' + job.Id; 

        plainTextBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '\n'
                + 'Status Detail: ' + job.Exception__c + '\n' 
                + 'Job Id: ' + job.Id;

        
        SendJobEmail(htmlBody,plainTextBody,subject,job.Emails__c);
    }
    public static void sendEmailOnFailuresWithErrors(Batch_Flow__c job, Boolean retryJob, Integer numberOfErrors) {    

        String htmlBody = '';
        String plainTextBody = '';
        String subject = 'Batch Flow Job(' + job.Name + ' - ' + job.Apex_Class__c + ') Completed with ' + numberOfErrors + ' Error(s)';

        if(retryJob) {

            htmlBody = 'Batch Flow is now attempting to re run this job.<br/><br/>';
            plainTextBody = 'Batch Flow is now attempting to re run this job.\n\n';
        }

        htmlBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '<br/>'
                + 'Status Detail: ' + job.Exception__c + '<br/>' 
                + 'Job Id: ' + job.Id; 

        plainTextBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '\n'
                + 'Status Detail: ' + job.Exception__c + '\n' 
                + 'Job Id: ' + job.Id;

        
        SendJobEmail(htmlBody,plainTextBody,subject,job.Emails__c);
    }
    public static void sendJobSummaryEmail(AsyncApexJob a, Batch_Flow__c job) {    

        String htmlBody;
        String plainTextBody;
        String subject = string.isBlank(job.Job_Summary_Email_Subject__c) 
                            ? 'Batch Flow Job(' + job.Name + ' - ' + job.Apex_Class__c + ') Completed'
                            :  job.Job_Summary_Email_Subject__c;

        htmlBody = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.<br/><br/>';
        plainTextBody = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n\n';

        htmlBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '<br/>' 
                + 'Job Id: ' + job.Id; 

        plainTextBody += 'Job: ' + job.Name + ' - ' + job.Apex_Class__c + '\n'
                + 'Job Id: ' + job.Id;


        SendJobEmail(htmlBody,plainTextBody,subject,job.Emails__c);
    }
    public static void SendDebugEmail(String htmlBody, String textBody, String subject, String email) {
        // Send an email to the specified email addresses with a report of how the batch job went
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(new List<String>{email});
        mail.setReplyTo('nick@sansotti.com');
        mail.setSenderDisplayName('Batch Flow');
        mail.setSubject(subject);
        mail.setPlainTextBody(textBody);
        mail.setHtmlBody(htmlBody);
        
        Messaging.reserveSingleEmailCapacity(1);

        List<Messaging.SendEmailResult> result = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{mail}
        );
    }
    public static void SendEmailOnException(Exception ex, String subject, String email) {
        // Send an email to a specified person describing an exception that occurred
        String htmlBody = 'Message: ' + ex.getMessage() + '<br/>'
            + 'Line Number: ' + ex.getLineNumber() + '<br/>'
            + 'Stack Trace:' + ex.getStackTraceString();
        String plainTextBody = 'Message: ' + ex.getMessage() + '\n'
            + 'Line Number: ' + ex.getLineNumber() + '\n'
            + 'Stack Trace:' + ex.getStackTraceString();
        SendDebugEmail(htmlBody,plainTextBody,subject,email);
    }
}