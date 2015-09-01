function addEnviromentInstallation(pipelineStateEntry,nEnviroment){
   return addInstallationId(pipelineStateEntry,nEnviroment);
}

function addBuildId(pipelineStateEnntry){
   return addBuildIdColumn(pipelineStateEnntry.host,
                                  pipelineStateEnntry.job,
                                  pipelineStateEnntry.installId);
}
function addExport(pipelineStateEntry){
   return addExportColumn(pipelineStateEntry);

}
function addNextInstallation(pipelineStateEntry,enviroment){
   return addNextInstallationColumn(pipelineStateEntry,enviroment);
}


function createDeploymentTable(){
   var installationIds=getInstallationIds().split(",");
   var enviroments=deploymentPipelineEnviroments;
   //Warning exporRepos is a PHASE in pipeline.sh
   enviroments[enviroments.length]=EXPORT_REPOS_ENVIROMENT;
   var head=data.sections[sectionPipeline].head;
   for (var i=0;i<enviroments.length;i++){
       head[i+2]=enviroments[i];
   }
   for (var i=0;i<installationIds.length;i++){
      var installInstance=installInstances[''+installationIds[i]+''];
      var rowData=new Array();
      var nColumn=0;
      rowData[nColumn++]=addConsoleColumn(installInstance.firstState.host,
                                          installInstance.firstState.job,
                                          installInstance.firstState.installId,
                                          installInstance.firstState.date);
      rowData[nColumn++]=addBuildId(installInstance.firstState);
      var nextInstallation=true;
      for (var j=0;j<enviroments.length;j++){
         var enviroment=enviroments[j];
         rowData[nColumn]="N/A";
         if (installInstance.enviroments.hasOwnProperty(enviroment)){
            rowData[nColumn]=addEnviromentInstallation(
                                 installInstance.enviroments[enviroment],j);
            if ((installInstance.enviroments[enviroment].state.phase == ACCEPTANCETEST_PHASE) &&
                (installInstance.enviroments[enviroment].state.result == stateOk)) {
               nextInstallation=true;
               } else{
                  nextInstallation=false;
               }
         } else{
            if (nextInstallation){
               if (enviroment == EXPORT_REPOS_ENVIROMENT){
                  //Suponemos que se ha hecho al menos una instalación en el primer entorno
                  if (installInstance.enviroments[enviroments[0]] != null){
                     rowData[nColumn]=addExport(installInstance.enviroments[enviroments[0]]);
                  }
               } else {
                  if (installInstance.enviroments[enviroments[0]] != null){
                      rowData[nColumn]=addNextInstallation(installInstance.enviroments[enviroments[0]],enviroment);
                  }
               }
               nextInstallation=false;
            }
         }
         nColumn++;
      }
      data.sections[sectionPipeline].data[i]=rowData;
   }
}
