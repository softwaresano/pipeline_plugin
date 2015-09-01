function getInstallInstance(installId){
   var installInstance=new Object();
   installInstance.installId=installId;
   installInstance.enviroments=new Object();
}

function getValidDataPipeline(pipelineStateEntry){
   //ExecutorPipeline Filter
   var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
   if (executorPipelines != pipelineStateEntry.pipelineId+"("+pipelineStateEntry.host+")"){
      return null;
   } else{ 
         //Deshechamos las entradas de la parte de building
         if (pipelineStateEntry.enviroment.indexOf("building(")>-1 ){
            return null;
         }
   }
   return pipelineStateEntry;
}

function addExecution(pipelineStateEntry){
   if (installInstances.hasOwnProperty(pipelineStateEntry.installId) == false){
      newInstallationIds=newInstallationIds+isNewType(newInstallationIds,pipelineStateEntry.installId);
      installInstances[''+pipelineStateEntry.installId+'']=new Object();
      installInstances[''+pipelineStateEntry.installId+''].enviroments=new Object();
      installInstances[''+pipelineStateEntry.installId+''].firstState=pipelineStateEntry;
   }
   if (pipelineStateEntry.state.phase != EXPORT_PHASE) {
      installInstances[''+pipelineStateEntry.installId+''].enviroments[pipelineStateEntry.enviroment]=pipelineStateEntry;
      if ((pipelineStateEntry.state.result == stateOk) && (pipelineStateEntry.state.phase == INSTALL_PHASE)){
         if (lastEnviromentInstallations[pipelineStateEntry.enviroment] != null){
            rollbackEnviromentInstallations[pipelineStateEntry.enviroment]=lastEnviromentInstallations[pipelineStateEntry.enviroment];
         }
         lastEnviromentInstallations[pipelineStateEntry.enviroment]=pipelineStateEntry;
      }
   } else {
      installInstances[''+pipelineStateEntry.installId+''].enviroments[EXPORT_REPOS_ENVIROMENT]=pipelineStateEntry;
   }
}
