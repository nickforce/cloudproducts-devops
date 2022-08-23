global class BatchFlowContacts implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Contact');
    }

    // Execute
    global void execute(Database.Batchablecontext BC, List<SObject> scope) {
        System.debug('batch flow contacts');
        System.debug(scope);
    }

    // Finish
    global void finish(Database.Batchablecontext BC) {
    
    }    

}