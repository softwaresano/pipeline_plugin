function addConsoleColumn(host,job,buildId,date){
   return "<a href=\"http://"+host+"/jenkins/job/"+job+"/"+buildId+"/consoleFull\">"+date+"<img src=\"./img/console.png\" alt=\"console\" ></a>";
}

function addBuildIdColumn(host,job,buildId){
   return "<a href=\"http://"+host+"/jenkins/job/"+job+"/"+buildId+"\">"+buildId+"</a>";
}
function addExportColumn(pipelineStateEntry){
   return "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+pipelineStateEntry.pipelineId+"-EXPORT/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+"\">Export</a>";
}
function addNextInstallationColumn(pipelineStateEntry,enviroment){
   var action="Upgrade"
   if (lastEnviromentInstallations.hasOwnProperty(enviroment)){
      if (lastEnviromentInstallations[enviroment].installId > pipelineStateEntry.installId){
         action="Downgrade";
      }
   }
   return "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
            pipelineStateEntry.pipelineId+"-ALL-01-"+INSTALL_PHASE+
            "/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+
            "&ENVIROMENT="+enviroment+"\">"+
            "<strong>"+action+"</strong></a>";
}

function addRollbackInstallationId(pipelineStateEntry){
         return "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
            pipelineStateEntry.pipelineId+"-ALL-01-"+INSTALL_PHASE+
            "/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+
            "&ENVIROMENT="+pipelineStateEntry.enviroment+"\">"+
            pipelineStateEntry.installId +
            "</a>";
}

function addInstallationId(pipelineStateEntry,nEnviroment){
   var installationUrl="";
   var reInstall="";
   var upgradeOrDowngrade="";
   if ( (pipelineStateEntry.state.result == stateKo) && 
        ((nEnviroment > 0) ||((nEnviroment == 0) && (pipelineStateEntry.state.phase != INSTALL_PHASE)))
      )
   {
         if (pipelineStateEntry.state.phase == EXPORT_PHASE ){
            reInstall= "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
            pipelineStateEntry.pipelineId+"-"+EXPORT_PHASE+
            "/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+"\">"+
            "<strong>Re-Export</strong></a>";

         } else {
            reInstall= "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
            pipelineStateEntry.pipelineId+"-ALL-01-"+INSTALL_PHASE+
            "/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+
            "&ENVIROMENT="+pipelineStateEntry.enviroment+"\">"+
            "<strong>Re-Install</strong></a>";
         }
   }
   var fullState=pipelineStateEntry.state.phase+"-"+pipelineStateEntry.state.result;
   if ((lastEnviromentInstallations.hasOwnProperty(pipelineStateEntry.enviroment)) &&
       (reInstall== "") && (pipelineStateEntry.state.result != stateExecuting)
   ){
      var action="";
      if (lastEnviromentInstallations[pipelineStateEntry.enviroment].installId > pipelineStateEntry.installId){
         action="Downgrade";
      } else if (lastEnviromentInstallations[pipelineStateEntry.enviroment].installId < pipelineStateEntry.installId){
         action="Upgrade";
      }
      if (action != ""){
         upgradeOrDowngrade="<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
            pipelineStateEntry.pipelineId+"-ALL-01-"+INSTALL_PHASE+
            "/buildWithParameters?N_BUILD="+pipelineStateEntry.installId+
            "&ENVIROMENT="+pipelineStateEntry.enviroment+"\">"+
            action +
            "</a>"
      }
   }
   
   return "<a href=\"http://"+pipelineStateEntry.host+"/jenkins/job/"+
         pipelineStateEntry.job+"/"+pipelineStateEntry.buildId+"\" >"+
         fullState+"<img src=\"./img/"+
         fullState+".png\" alt=\""+
         fullState+"\" tooltip=\""+
         fullState+"\"></a>"+
         reInstall+upgradeOrDowngrade;
}
