var lastEnviromentInstallations=new Object();
var rollbackEnviromentInstallations=new Object();
var installInstances=new Object();
var pipelineIds=FIELD_SEPARATOR;
var enviroments=FIELD_SEPARATOR;
var newInstallationIds=FIELD_SEPARATOR;
var triggers=FIELD_SEPARATOR;
var phases=FIELD_SEPARATOR;
var resultStates=FIELD_SEPARATOR; //Different states in the log.
var causes="";
var states="";
var statesOk=0;
var statesKo=0;
var statesExecuting=0;
var statesAborted=0;
var triggerByUsers=0;
var triggerByScm=0;
var triggerByUpStream=0;
var nStat=0;
var statesStats=new Object();
var pipelineStats=new Object();
var pipelineByStates=null;
var pipelineByEnviroment=null;
var phaseByStates=null;
var firstExecution=null;

function isNewType(type,value){
   if ((value == null) || (value=="")){
      return "";
   }
   if (type.indexOf(FIELD_SEPARATOR+value+FIELD_SEPARATOR) == -1){
         return value+FIELD_SEPARATOR;
   }
   return "";
}

function getAllItems(value){
   return value.substring(1,value.length-1).replace(/\|/gi, ',');
}

function getNEnviroments(){
   return enviroments.split(FIELD_SEPARATOR).length-2;
}

function getEnviroments(){
   return getAllItems(enviroments);
}

function getNPipelineIds(){
   return pipelineIds.split(FIELD_SEPARATOR).length-2;
}

function getPipelineIds(){
   return getAllItems(pipelineIds);
}

function getPhases(){
   return getAllItems(phases);
}

function getTriggers(){
   return getAllItems(triggers);

}

function getTotalTrigger(){
   return triggerByUsers+triggerByScm+triggerByUpStream
}

function getTriggerStat(idStat){
   return idStat*100/getTotalTrigger()+"("+idStat+"/"+getTotalTrigger()+")";

}

function getManualTrigger(){
   return getTriggerStat(triggerByUsers);
}

function getScmTrigger(){
   return getTriggerStat(triggerByScm);
}

function getUpstreamTrigger(){
   return getTriggerStat(triggerByUpStream);
}


function getResultStates(){
   return getAllItems(resultStates);
}

function getInstallationIds(){
   return getAllItems(newInstallationIds);
}



function getSuccessfullState(pipelineStateEntry){
   var fullState=getFullState(pipelineStateEntry);
   var stateWithResult=fullState.substring(0,fullState.lastIndexOf("-"));
   var nExecutings=0;
   var nOks=0;
   var tendency="none";
   if (statesStats.hasOwnProperty(stateWithResult+"-"+stateExecuting)) {
      nExecutings=statesStats[stateWithResult+"-"+stateExecuting];
   }
   if (statesStats.hasOwnProperty(stateWithResult+"-"+stateOk)) {
      nOks=statesStats[stateWithResult+"-"+stateOk];
   }
   if (nExecutings == 0){
      if (nOks > 0){
         return "100"+addImgElement("img/tendency/"+tendency+".png",tendency,tendency);
      } else {
         return "0"+addImgElement("img/tendency/"+tendency+".png",tendency,tendency);
      }
   }
   var successRate=nOks*100/nExecutings;
   
   if (pipelineStateEntry.state.result == stateOk ){
      tendency="better";
      }
   else{
      if (pipelineStateEntry.state.result == stateKo){
         tendency="worse";
      } 
      else{
         if (pipelineStateEntry.state.result == stateAborted){
            tendency="worse";
         }
      }
   }
   return successRate+" ("+nOks+"/"+nExecutings+")"+addImgElement("img/tendency/"+tendency+".png",tendency,tendency);
}

function clearStats(){
   nStat=0;
   enviroments=FIELD_SEPARATOR;
   pipelineIds=FIELD_SEPARATOR;
   phases=FIELD_SEPARATOR;
   resultStates=FIELD_SEPARATOR;
   triggers=FIELD_SEPARATOR;
   newInstallationIds=FIELD_SEPARATOR;
   causes="";
   states="";
   triggerByUsers=0;
   triggerByScm=0;
   triggerByUpStream=0;
   statesOk=0;
   statesKo=0;
   statesExecuting=0;
   statesAborted=0;
   statesStats=new Object();
   pipelineStats=new Object();
   pipelineStats.byEnviroment=new Object();
   pipelineStats.byPipeline=new Object();
   pipelineStats.byPhase=new Object();
   pipelineStats.byJob=new Object();
   pipelineStats.byScmTrigger=new Object();
   pipelineStats.byUserTrigger=new Object();
   pipelineStats.byUpstreamTrigger=new Object();
   data.sections[sectionStats].data=new Array();
   lastEnviromentInstallations=new Object();
   rollbackEnviromentInstallations=new Object();
   installInstances=new Object();
   firstExecution=null;
}

function newEntry(){
   var entry=new Object();
   entry.ok=0;
   entry.ko=0;
   entry.aborted=0;
   entry.executing=0;
   return entry;
}

function statsByState(pipelineStateEntry,statObject,key){
   var entry=null;
   if (statObject.hasOwnProperty(key)) {
       entry=statObject[key];
   } else {
      entry=newEntry();
   }
   entry.date=pipelineStateEntry.date;
   if (pipelineStateEntry.state.result == stateOk){
      entry.ok++;
   } else if (pipelineStateEntry.state.result == stateKo){
      entry.ko++;
   } else if (pipelineStateEntry.state.result == stateExecuting){
      entry.executing++;
   } else if (pipelineStateEntry.state.result == stateAborted){
      entry.aborted++;
   }
   statObject[key]=entry;
}

function statStateOk(pipelineStateEntry){
   statesOk++;
   statsByState(pipelineStateEntry,pipelineStats.byEnviroment,pipelineStateEntry.enviroment);
   statsByState(pipelineStateEntry,pipelineStats.byPipeline,pipelineStateEntry.pipelineId+"("+pipelineStateEntry.host+")");
   statsByState(pipelineStateEntry,pipelineStats.byPhase,pipelineStateEntry.state.phase);
   statsByState(pipelineStateEntry,pipelineStats.byJob,pipelineStateEntry.job);
}

function statStateKo(pipelineStateEntry){
   statesKo++;
   //stateEnviroment(pipelineStateEntry)
}

function statStateExecuting(pipelineStateEntry){
   statesExecuting++;
   //stateEnviroment(pipelineStateEntry)
}

function statStateAborted(pipelineStateEntry){
   statesAborted++;
   //stateEnviroment(pipelineStateEntry)
}

function processTriggerStat(triggerReason){
   if (triggerReason == trigger_type_upstreamProject){
      triggerByUpStream++;
   } else {
      if (triggerReason == trigger_type_userId){
         triggerByUsers++;
      } else {
         if (triggerReason == trigger_type_scm){
            triggerByScm++;
         } 
      }
   }
}
function stringToDate(stringDate){
   return new Date(stringDate.substring(6,10),
               stringDate.substring(3,5) - 1,
               stringDate.substring(0,2),
               stringDate.substring(11,13),
               stringDate.substring(14,16),
               stringDate.substring(17,19),
               0
               );
}

function processDate(pipelineStateEntry){
   var newDate=stringToDate(pipelineStateEntry.date);
   if (firstExecution == null){
      firstExecution=newDate;
   } else{
      if (firstExecution > newDate){
         firstExecution=newDate;
      }
   }
}

function processStat(pipelineStateEntry){
   //Nº pipelines
   pipelineIds=pipelineIds+isNewType(pipelineIds,new String(pipelineStateEntry.pipelineId+"("+pipelineStateEntry.host+")"));
   //Nº Enviroments
   enviroments=enviroments+isNewType(enviroments,pipelineStateEntry.enviroment);
   //Phase
   phases=phases+isNewType(phases,pipelineStateEntry.state.phase);
   var triggerReason="scm";
   if (pipelineStateEntry.trigger != triggerReason ){
      triggerReason=pipelineStateEntry.trigger.substring(0,pipelineStateEntry.trigger.indexOf("("));
   }
   triggers=triggers+isNewType(triggers,triggerReason);
   if (pipelineStateEntry.state.result!=stateExecuting) {
      processTriggerStat(triggerReason);
      processDate(pipelineStateEntry);
   }
   //Result States
   resultStates=resultStates+isNewType(resultStates,pipelineStateEntry.state.result);
   if (pipelineStateEntry.state.result==stateOk){
      statStateOk(pipelineStateEntry);
   } else 
      if (pipelineStateEntry.state.result==stateKo){
         statStateKo(pipelineStateEntry);
      } else 
         if (pipelineStateEntry.state.result==stateExecuting){
            statStateExecuting(pipelineStateEntry);
         }  else
              if (pipelineStateEntry.state.result==stateOk){
                 statStateAborted(pipelineStateEntry);
              }
   var fullState=getFullState(pipelineStateEntry);
   if (statesStats.hasOwnProperty(fullState)) {
      statesStats[fullState]=statesStats[fullState]+1;
   } else {
      statesStats[fullState]=1;
   }
}

function addStat(idStat,value){
   data.sections[sectionStats].data[nStat]=new Array();
   data.sections[sectionStats].data[nStat][0]=idStat;
   data.sections[sectionStats].data[nStat++][1]=value;
}



function dataGraph(){
   var nStates=0;
   var dataStatesStats=new Array();
   dataStatesStats[nStates++]=statesFinalResult;
   var states=new Object();
   var arrayStates=new Array();
   for (var k in statesStats) {
      states[k.substring(0,k.lastIndexOf("-"))]=1;
   }
   var i=0;
   var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
   for (var k in states) {
      arrayStates[i++]=k;
   }
   arrayStates.sort();
   for (var k=0;k<arrayStates.length;k++) {
      dataStatesStats[nStates]=new Array();
      dataStatesStats[nStates][0]=arrayStates[k];
      for (var i=1;i<dataStatesStats[0].length;i++){
         var index=arrayStates[k];
         if (executorPipelines != "null"){
            index=executorPipelines+arrayStates[k];
         }
         if (statesStats.hasOwnProperty(arrayStates[k]+"-"+dataStatesStats[0][i])){
            dataStatesStats[nStates][i]=statesStats[arrayStates[k]+"-"+dataStatesStats[0][i]];
         } else{
            dataStatesStats[nStates][i]=0;
         }
      }
       if (executorPipelines != "null"){
         dataStatesStats[nStates][0]=dataStatesStats[nStates][0].substring(executorPipelines.length+1);
         var state=dataStatesStats[nStates][0].substring(dataStatesStats[nStates][0].lastIndexOf("-")+1);
         if (state==EXPORT_PHASE){
            dataStatesStats[nStates][0]=state
         } else {
            dataStatesStats[nStates][0]=dataStatesStats[nStates][0].substring(0,dataStatesStats[nStates][0].indexOf(" "))+" "+state;
         }
      }
      nStates++;
   };
   return dataStatesStats;
}

function statExecutionsByHour(){
   var now = new Date();
   if ((firstExecution != null)&&(statesExecuting > 0)){
      return statesExecuting/((now.getTime()-firstExecution.getTime())/3600000);
   }
   return "N/A";
}
function refreshDataStats(){
   nStat=0;
   if (data.sections[sectionData].data.length == 0){
      return;
   }
   addStat("items",data.sections[sectionData].data.length);
   if (statesExecuting > 0){
      addStat("Successfull States(%)",statesOk*100/statesExecuting + "("+statesOk+"/"+statesExecuting+")");
      addStat("Failure States(%)",statesKo*100/statesExecuting + "("+statesKo+"/"+statesExecuting+")");
      addStat("Aborted States(%)",statesAborted*100/statesExecuting + "("+statesAborted+"/"+statesExecuting+")");
   }
   addStat("Best State(s):","To be implemented");
   addStat("Worst State(s):","To be implemented");
   addStat("Best Pipeline(s):","To be implemented");
   addStat("Worst Pipeline(s):","To be implemented");
   addStat("nº pipelines",getNPipelineIds());
   addStat("Pipeline Ids",getPipelineIds());
   addStat("nº Enviroments",getNEnviroments());
   addStat("Enviroments",getEnviroments());
   addStat("Manual Trigger(%)",getManualTrigger());
   addStat("Scm Trigger(%)",getScmTrigger());
   addStat("UpStream Trigger(%)",getUpstreamTrigger());
   addStat("Executions by Hour",statExecutionsByHour());
}

function getFullState(pipelineStateEntry){
   return new String(pipelineStateEntry.pipelineId+"("+pipelineStateEntry.host+") "+pipelineStateEntry.enviroment+" "+pipelineStateEntry.state.id);
}


