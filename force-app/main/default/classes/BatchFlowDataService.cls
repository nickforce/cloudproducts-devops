public without sharing class BatchFlowDataService {
    
    @AuraEnabled(cacheable=true scope='global')
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds, String country) {
        searchTerm = '%' + searchTerm + '%';
        
        List<ApexClass> locations = [
            SELECT Name, Id
            FROM ApexClass
            WHERE
                Name LIKE :searchTerm
                AND Id NOT IN :selectedIds
                AND NamespacePrefix = null
                AND Name != 'BatchFlow'
            LIMIT 5
        ];
        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        for (ApexClass entry : locations) {
            results.add(new LookupSearchResult(entry.Id, null, null, entry.Name, null));
        }
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ApexClass> getBatchApexClasses() {
        List<ApexClass> classList = new List<ApexClass>();
        for(ApexClass c : [SELECT Name, Body
                           FROM ApexClass
                           WHERE NamespacePrefix = null
                           AND Name != 'BatchFlow'
                           ORDER BY Name ASC]) {
            
            // 1. first perform a contains to find all classes (for performance must do this check first)
            // 2. (performance heavy) Next attempt to cast the class name into type of batchable interface with a no arg constructor
            if(c.Body.containsIgnoreCase('Database.Batchable<sObject>')) {

                try {
                    system.type t = system.type.forname(c.Name);
                    if(t != null && t.newInstance() instanceof database.batchable<sObject>) {
                        classList.add(c);
                    }
                }
                catch(Exception e) {

                }
            }
        }
        return classList;
    }
    @AuraEnabled
    public static string upsertBatchFlow(Object data){
        
        Batch_Flow__c upsertBatchFlow = (Batch_Flow__c)JSON.deserialize(
            JSON.serialize(data),
            Batch_Flow__c.class
        );
        upsert upsertBatchFlow;
        return 'Success: Batch Flow upserted successfully';
    }
    @AuraEnabled
    public static Batch_Flow_Sch__c querySelectedBatchFlowSch(Object data){
        Batch_Flow_Sch__c selectedBatchFlowSch = (Batch_Flow_Sch__c)JSON.deserialize(
            JSON.serialize(data),
            Batch_Flow_Sch__c.class
        );

        return [SELECT Id, Name, Frequency__c, Day_of_Month__c,
                    Start_Date__c, End_Date__c, Preferred_Start_Time__c
                FROM Batch_Flow_Sch__c
                WHERE Id = :selectedBatchFlowSch.Id
                LIMIT 1][0];
    }
    @AuraEnabled
    public static string upsertBatchFlowSch(Object data){
        
        Batch_Flow_Sch__c upsertBatchFlowSch = (Batch_Flow_Sch__c)JSON.deserialize(
            JSON.serialize(data),
            Batch_Flow_Sch__c.class
        );
        upsert upsertBatchFlowSch;
        return 'Success: Batch Flow upserted successfully';
    }
    @AuraEnabled(cacheable=true)
    public static List<Batch_Flow_Sch__c> getBatchFlowSchedules(){
        List<Batch_Flow_Sch__c> flowSchs = new List<Batch_Flow_Sch__c>();
        flowSchs = [SELECT Id, Name
                    FROM Batch_Flow_Sch__c];

        return flowSchs;
    }
}