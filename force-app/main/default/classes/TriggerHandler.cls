public virtual class TriggerHandler {
    
    Public TriggerParameters tp {get; private set;}
 
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    public Boolean isGlobalBypassOn { get; private set;}

    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }
 
    public TriggerHandler() {
        //isGlobalBypassOn = util_Methods.GlobalBypass();
        isGlobalBypassOn = false;
    }
 
    public void run() {
        
        if(!validateRun()) return;
        
        tp = new TriggerParameters(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap,
                                    Trigger.isBefore, Trigger.isAfter, Trigger.isDelete, 
                                    Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete, Trigger.isExecuting);
                                    
        addToLoopCount();  
  
        // dispatch to the correct handler method
        if(Trigger.isBefore && Trigger.isInsert) {
            this.beforeInsert();
        }
        else if(Trigger.isBefore && Trigger.isUpdate) {
            this.beforeUpdate();
        }
        else if(Trigger.isBefore && Trigger.isDelete) {
            this.beforeDelete();
        }
        else if(Trigger.isAfter && Trigger.isInsert) {
            this.afterInsert();
        }
        else if(Trigger.isAfter && Trigger.isUpdate) {
            this.afterUpdate();
        }
        else if(Trigger.isAfter && Trigger.isDelete) {
            this.afterDelete();
        }
        else if(Trigger.isAfter && Trigger.isUndelete) {
            this.afterUndelete();
        }
    }
  
    /***************************************
    * context methods
    ***************************************/

    // context-specific methods for override
    protected virtual void beforeInsert(){}
    protected virtual void beforeUpdate(){}
    protected virtual void beforeDelete(){}
    protected virtual void afterInsert(){}
    protected virtual void afterUpdate(){}
    protected virtual void afterDelete(){}
    protected virtual void afterUndelete(){}

  
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        }
        else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }
  
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }
  
    private Boolean validateRun() {
        if(isGlobalBypassOn) return false;

        if(!Trigger.isExecuting) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }
        
        return true;
    }
  
    private void addToLoopCount() {
        
        system.debug('$$$$$$$$$$$$$$$$$$$$$$$$$');
        String handlerName = getHandlerName();
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            system.debug('$$$$$$$$$$$$$$$$$$$$$$$$$');
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        } 
        /* nj uber
        else if(tp.map_MaxCount.containskey(handlerName)) {
            system.debug('$$$$$$$$$$$$$$$$$$$$$$$$$');
            setMaxLoopCount(Integer.Valueof(tp.map_MaxCount.get(handlerName).Max_Loop_Count__c));
        }
        */
    }
  
    // inner class for managing the loop count per handler
    private class LoopCount {
        
        private Integer max;
        private Integer count;

        public LoopCount() {    
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if(this.max < 0) return false;
            
            if(this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }
  
    // exception class
    public class TriggerHandlerException extends Exception {
  
    }
}