@isTest
private class BatchFlowTest {
    static Batch_Flow__c batchFlow {get;set;}
    static Batch_Flow__c batchFlow2 {get;set;}
    static BatchFlow_Config__c flowConfig {get;set;}

    static testMethod void scheduleBatchFlowDefaults() {
        init();
        Test.StartTest();

        // clear asyncapexjobid
        batchFlow.AsyncApexJobId__c = null;
        update batchFlow;
        system.assert(batchFlow.AsyncApexJobId__c == null);

        //Get the system date and time.
        Datetime dt = DateTime.now().addSeconds(5);
        String sch = String.valueOf( dt.second() ) + ' ' + String.valueOf( dt.minute()   ) + ' ' + String.valueOf( dt.hour() ) + ' '  + String.valueOf( dt.day() ) +  ' ' + String.valueOf( dt.month() ) + ' '  + '? ' + String.valueOf( dt.Year());
        // schedule mgr to run
        BatchFlow batch = new BatchFlow();
        Id cronId = system.schedule('Batch Flow Daemon', sch, batch);
        system.assert(cronId != null);

        Test.StopTest();
    }

    static testMethod void failedJobTrigger() {        
        init();
        batchFlow.Next_Job__c = batchFlow2.Id;
        update batchFlow;

        Test.StartTest();
        // set job to failed status
        batchFlow.Status__c = 'Failed';
        // set next job to null to unschedule the job
        batchFlow.Next_Job__c = null;
        update batchFlow;
        system.assert(batchFlow.Status__c == 'Failed');
        Test.StopTest();
    }

    static void Init() {
        // create config record
        flowConfig = new BatchFlow_Config__c();
        flowConfig.Name = 'Config';
        flowConfig.Monitor_Jobs__c = false;
        flowConfig.Frequency__c = 5;
        insert flowConfig;

        // create 1 active job
        batchFlow = new Batch_Flow__c();
        batchFlow.Name = 'test';
        batchFlow.Apex_Class__c = 'test';
        // setup start and end time for job to make job active
        batchFlow.Active__c = true;
        batchFlow.StartTime__c = system.today();
        batchFlow.EndTime__c = system.today().addDays(2);
        batchFlow.Next_Scheduled_Run__c = system.now().addDays(-1);
        batchFlow.Status__c = 'Started';
        batchFlow.AsyncApexJobId__c = 'test';
        batchFlow.Scope_Size__c = 5;
        insert batchFlow;

        system.assert(batchFlow.Next_Scheduled_Run__c != null);
        system.assert(batchFlow.Status__c != null);
        system.assert(batchFlow.AsyncApexJobId__c != null);


        // create 1 active job
        batchFlow2 = new Batch_Flow__c();
        batchFlow2.Name = 'test';
        batchFlow2.Apex_Class__c = 'test';
        // setup start and end time for job to make job active
        batchFlow.Active__c = true;
        batchFlow2.StartTime__c = system.today();
        batchFlow2.EndTime__c = system.today().addDays(2);
        batchFlow2.Next_Scheduled_Run__c = system.now();
        batchFlow2.Status__c = 'Completed';
        batchFlow2.AsyncApexJobId__c = 'test';
        insert batchFlow2;
    }
}