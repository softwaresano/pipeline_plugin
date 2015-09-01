function getValidDataLog(index,pipelineStateEntry){
   var interval=getURLParameter(PARAM_INTERVAL);
   //Interval filter
   if (interval != "null"){
      var date=new Date(pipelineStateEntry.date.substring(6,10),parseInt(pipelineStateEntry.date.substring(3,5))-1, pipelineStateEntry.date.substring(0,2),pipelineStateEntry.date.substring(11,13), pipelineStateEntry.date.substring(14,16), pipelineStateEntry.date.substring(17,19), 0);
      var limitDate=new Date();
      limitDate.setDate(limitDate.getDate()-parseInt(interval));
      if (date.getTime()<=limitDate.getTime()){
         return null;
      }
   }
   //Enviroment Filter
   var enviroment=getURLParameter(PARAM_ENVIROMENT);
   if ((enviroment != "null") && (enviroment != pipelineStateEntry.enviroment)){
      return null;
   }
   //Pipeline Filter
   var pipeline=getURLParameter(PARAM_PIPELINE);
   if ((pipeline != "null") && (pipeline != pipelineStateEntry.pipelineId+"("+pipelineStateEntry.host+")")){
      return null;
   }
   //Result State
   var resultState=getURLParameter(PARAM_RESULTSTATE);
   if (resultState != "null") {
      if (resultState != EXECUTION_TRANSITION){
         if (resultState != pipelineStateEntry.state.result){
            return null;
         }
      } else{
         if (pipelineStateEntry.state.result != stateExecuting ){
            return null;
         }
         if ((pipelineStateEntry.state.result == stateExecuting ) && 
             (isInExecution(index,pipelineStateEntry) == false)){
         return null;
         }
      }
   }
   //Phase
   var phase=getURLParameter(PARAM_PHASE);
   if ((phase != "null") && (phase != pipelineStateEntry.state.phase)){
      return null;
   }
   var trigger=getURLParameter(PARAM_TRIGGER);
   if ((trigger != "null") && (pipelineStateEntry.trigger.indexOf(trigger)<0)){
      return null;
   }
   
   return pipelineStateEntry;

}

