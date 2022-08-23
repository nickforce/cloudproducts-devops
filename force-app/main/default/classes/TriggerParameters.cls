public class TriggerParameters {
    /** 
    * @description A enum that represents the trigger event.
    */
    
    public Enum TriggerEvent { beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete }
    public TriggerEvent tEvent;
        
    
    public boolean beforeInsert = false;
    public boolean afterInsert = false;    
    public boolean beforeUpdate = false;
    public boolean afterUpdate = false;    
    public boolean beforeDelete = false;
    public boolean afterDelete = false;    
    public boolean afterUndelete = false;        
    
    public List<SObject> oldList { get; private set; }
    public List<SObject> newList { get; private set; }
    public Map<Id, SObject> oldMap { get; private set; }
    public Map<Id, SObject> newMap { get; private set; }
    public String triggerObject { get; private set; }
    public Boolean isExecuting { get; private set;}
    
    /* nj uber
    public Map<String,Local_Bypass__c> map_localBypass  { get; private set;}
    public Map<String,Local_Bypass__c> map_MaxCount  { get; private set;}
    */
    
    /** 
    * @description Constructs the TriggerParameter object.
    * @param List<SObject> A list of records with the state of 'before' event.
    * @param List<SObject> A list of records with the state of 'after' event.
    * @param Map<Id, SObject> A map of records with the state of 'before' event.
    * @param Map<Id, SObject> A map of records with the state of 'after' event.
    * @param Boolean A flag to indicate 'isBefore' event.
    * @param Boolean A flag to indicate 'isAfter' event.
    * @param Boolean A flag to indicate 'isDelete' event.
    * @param Boolean A flag to indicate 'isInsert' event.
    * @param Boolean A flag to indicate 'isUpdate' event.
    * @param Boolean A flag to indicate 'isUnDelete' event.
    * @param Boolean A flag to indicate 'isExecuting'.
    */
    public TriggerParameters(List<SObject> olist, List<SObject> nlist, Map<Id, SObject> omap, Map<Id, SObject> nmap,
                                Boolean ib, Boolean ia, Boolean id, Boolean ii, Boolean iu, Boolean iud, Boolean ie) {
        this.oldList = olist;
        this.newList = nlist;
        this.oldMap = omap;
        this.newMap = nmap;
        this.triggerObject = getSObjectTypeName((this.oldList != null && this.oldList.size() > 0) ? this.oldList[0] : this.newList[0]);
        
        if (ib & ii) tEvent = TriggerEvent.beforeInsert;
        else if (ib && iu) tEvent = TriggerEvent.beforeUpdate;
        else if (ib && id) tEvent = TriggerEvent.beforeDelete;
        else if (ia && ii) tEvent = TriggerEvent.afterInsert;
        else if (ia && iu) tEvent = TriggerEvent.afterUpdate;
        else if (ia && id) tEvent = TriggerEvent.afterDelete;
        else if (ia && iud) tEvent = TriggerEvent.afterUndelete;
 
 
        if (ib & ii) beforeInsert = true;
        else if (ib && iu) beforeUpdate = true;
        else if (ib && id) beforeDelete = true;
        else if (ia && ii) afterInsert = true;
        else if (ia && iu) afterUpdate = true;
        else if (ia && id) afterDelete = true;
        else if (ia && iud) afterUndelete = true;
   
 
        isExecuting = ie;

        /* nj uber
        map_MaxCount = new Map<String,Local_Bypass__c>();
        map_localBypass = new Map<String,Local_Bypass__c>();
        
        if(!Local_Bypass__c.getall().isEmpty()) {        
            for(Local_Bypass__c lb : Local_Bypass__c.getall().values()) {        
                if(lb.Method_Name__c != null) {        
                    map_localBypass.put(lb.Method_Name__c,lb);        
                }
            }        
        } 
        map_MaxCount = Local_Bypass__c.getall();
        */
    }
    
    public static String getSObjectTypeName(SObject so) {
        return so.getSObjectType().getDescribe().getName();
    }
}