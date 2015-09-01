#!/bin/bash

if [[ -z "$DP_HOME" ]]; then
   DP_HOME=$(dirname $(readlink -f $(which dp_package.sh 2>/dev/null) 2>/dev/null) 2>/dev/null)
   [[ -z "$DP_HOME" ]] && echo "[ERROR] DP_HOME must be defined" && exit 1
fi

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi
. /home/develenv/bin/setEnv.sh

init(){
   standardParameterREGEX="^[a-z0-9A-Z]+$"
   versionParameterREGEX="^[0-9]+(\.[0-9]+)*$"
   MODULE_TEMPLATE_DIR=$DP_HOME/admin/templates
   JOBS_DIR=$PROJECT_HOME/app/jenkins/jobs
   NEXT_STEPS_FILE="$JOBS_DIR/pipeline-ADMIN-01-addPipeline/workspace/NEXT_STEPS.html"
   mkdir -p $JOBS_DIR
   getHostname
   develenvHost=$HOST
}
getHostname(){
   IP=`LANG=C /sbin/ifconfig | grep "inet addr" | grep "Bcast" | awk '{ print $2 }' | awk 'BEGIN { FS=":" } { print $2 }' | awk ' BEGIN { FS="." } { print $1 "." $2 "." $3 "." $4 }'`
   MAC_ADDRESSES=`LANG=C /sbin/ifconfig -a|grep HWaddr|awk '{ print $5 }'`
   if [ "$IP" == "" ]; then
      _message "\nNo hay conexión de red. Introduce el nombre o la ip de la máquina: \c"
      read HOST
   else
      local j=0
      for i in $IP; do
         #Averiguamos si alguna IP tiene asignada nombre de red
         j=$(($j +1 ));
         temp=`LANG=C nslookup $i|grep "name = "|cut -d= -f2| sed 's/.//' | sed 's/.$//'`
         if [ "$temp" != "" ]; then
            HOST=$temp
            INTERNALIP=$i
            MAC_ADDRESS=`echo $MAC_ADDRESSES|cut -d' ' -f$j`
            # Avoid problem with virtuals ips
            if [ "$(echo $temp|cut -d'.' -f1)" == "$(echo $(hostname)|cut -d'.' -f1)" ]; then
                break
            fi
         fi
      done
      if [ "$HOST" == "" ]; then
         # Probablemente sea una conexión wifi, y no tenga asignada un nombre en el DNS
         HOST=`hostname`
         INTERNALIP=`echo $IP|cut -d' ' -f1`
         MAC_ADDRESS=`echo $MAC_ADDRESSES|cut -d' ' -f1`
         # Si no hay un nombre de hosts asignado
         if [ "$HOST" == "" ];then
            # Nos quedamos con la primera IP
            HOST=$INTERNALIP
         fi
      fi
   fi
}


function reloadJenkinsMessage(){
   _log "[INFO] Reload jenkins configuration to aply the last changes (http://$develenvHost/jenkins/reload)."
}

function nextSteps(){
   fileNextStep="$1"
   jobsToConfigure="$2"
   if ! [ -f $fileNextStep ]; then
      reviewInstallJob=`echo $jobsToConfigure|sed s:"-.*":"-ALL-01-install":g`
      echo -e "
   <html>
      <body>
      <script type=\"text/javascript\">
         function submitform()
         {
            document.forms[\"myform\"].submit();
         }
      </script>
         <p>Para acabar de configurar el pipeline realiza los siguientes pasos, segÃºn el orden que se muestran:</p>
         <form id=\"myform\" action=\"/jenkins/reload\" method=\"POST\">
            <a href=\"javascript: submitform()\">Reload Jenkins</a>
         </form>
         <br/><a href=\"/jenkins/job/$reviewInstallJob/configure\">Revisar tabla de despliegues</a>
         <p>Exportar la clave pÃºblica del usuario develenv /home/develenv/.ssh/id_dsa.pub al usuario [$adminUser] de las mÃ¡quinas en la que accede el pipeline</p>
      </body>
   </html>" >$fileNextStep
   fi
   for jobToConfigure in $jobsToConfigure; do
      if [ "`cat $fileNextStep|grep \"$jobToConfigure\"`" == "" ]; then
         substitute="<br/><a href=\"/jenkins/job/$jobToConfigure/configure\">Configurar repositorio de fuentes para $jobToConfigure</a>"
         sed -i s:"</body>":"${substitute}</body>":g $fileNextStep
      fi
   done;
   sed -i s:"</body>":"   <p>* Cada módulo puede tener dependencias de librerías, asegurarse que exite el job que genera el build para dichas librerías<p></body>":g $fileNextStep
   _log "[INFO] Para acabar de configurar el pipeline sigue las instrucciones que se describen en el fichero Next_steps"
}

function configureSCMJobMessage(){
   jobsToConfigure="$1"
   _log "[WARNING] Configura el repositorio de fuentes para los jobs [$jobsToConfigure]"
   if [ "$JOB_NAME" != "" -a "$JOB_NAME" == "pipeline-ADMIN-02-addModuleToPipeline" ]; then
      #Se está añadiendo el módulo al pipeline mediante jenkins
      rm -Rf $JOBS_DIR/pipeline-ADMIN-02-addModuleToPipeline/workspace/NEXT_STEPS.html
      nextSteps "$JOBS_DIR/pipeline-ADMIN-02-addModuleToPipeline/workspace/NEXT_STEPS.html" "$jobsToConfigure"
   else
      # Se está creando un pipeline
      nextSteps "$NEXT_STEPS_FILE" "$jobsToConfigure"
   fi
}

function addJenkinsView(){
   view=$1
   sed -i s:"</views>":"$view</views>":g $PROJECT_HOME/app/jenkins/config.xml
}

function addJenkinsPipelineView(){
   buildPipelineView="<au.com.centrumsystems.hudson.plugin.buildpipeline.BuildPipelineView>\
      <owner class=\"hudson\" reference=\"../../..\"/>\
      <name>$projectName $moduleName pipeline</name>\
      <description>\&lt;a href=\&quot;http\://www.softwaresano.com/\&quot; title=\&quot;SoftwareSano\&quot; class=\&quot;poweredBy\&quot;\&gt;\&#xd;\
   \&lt;script type=\&quot;text/javascript\&quot; src=\&quot;http\://www.softwaresano.com/widgets/jenkinsViewBuiltBy.php\&quot;\&gt;\&lt;/script\&gt;\&#xd;\
   \&lt;script type=\&quot;text/javascript\&quot; src=\&quot;/widgets/jenkinsViewBuiltBy.php\&quot;\&gt;\&lt;/script\&gt;\&#xd;\
\&lt;/a\&gt;\&#xd;\
\&lt;br/\&gt;\&#xd;\
\&lt;h3\&gt;Builds del módulo[$moduleName]\&lt;/h3\&gt;\&#xd;\
La documentación de la deployment pipeline está disponbile \&#xd;\
\&lt;a href=\&quot;http\://develenv.softwaresano.com/deploymentPipeline/index.html\&quot; title=\&quot;Deployment Pipeline class=\&quot;poweredBy\&quot;\&gt;aquí \&#xd;\
\&lt;/a\&gt;\&#xd;\
</description>\
      <filterExecutors>false</filterExecutors>\
      <filterQueue>false</filterQueue>\
      <properties class=\"hudson.model.View$PropertyList\"/>\
      <selectedJob>$fullJobName</selectedJob>\
      <noOfDisplayedBuilds>10</noOfDisplayedBuilds>\
      <buildViewTitle>$projectName $moduleName Pipeline</buildViewTitle>\
      <triggerOnlyLatestJob>false</triggerOnlyLatestJob>\
    </au.com.centrumsystems.hudson.plugin.buildpipeline.BuildPipelineView>"
   addJenkinsView "$buildPipelineView"
}

function addJenkinsProjectView(){
   projectJenkinsView="    <hudson.plugins.view.dashboard.Dashboard>\
      <owner class=\"hudson\" reference=\"../../..\"/>\
      <name>${projectName}</name>\
<description>\&lt;a href=\&quot;http\://www.softwaresano.com/\&quot; title=\&quot;SoftwareSano\&quot; class=\&quot;poweredBy\&quot;\&gt;\&#xd;\
   \&lt;img id=\&quot;viewJenkins\&quot; class=\&quot;poweredBy\&quot;  alt=\&quot;softwaresano\&quot; src=\&quot;http\://pimpam.googlecode.com/files/viewJenkins.png\&quot;/\&gt;\&#xd;\
   \&lt;script type=\&quot;text/javascript\&quot; src=\&quot;http\://www.softwaresano.com/widgets/jenkinsViewBuiltBy.php\&quot;\&gt;\&lt;/script\&gt;\&#xd;\
   \&lt;script type=\&quot;text/javascript\&quot; src=\&quot;/widgets/jenkinsViewBuiltBy.php\&quot;\&gt;\&lt;/script\&gt;\&#xd;\
\&lt;/a\&gt;\&#xd;\
\&lt;br/\&gt;\&#xd;\
\&lt;h3\&gt;All jobs in  ${projectName} pipeline\&lt;/h3\&gt;\&#xd;\
La documentación de la deployment pipeline está disponbile \&#xd;\
\&lt;a href=\&quot;http\://develenv.softwaresano.com/deploymentPipeline/index.html\&quot; title=\&quot;Deployment Pipeline class=\&quot;poweredBy\&quot;\&gt;aquí \&#xd;\
\&lt;/a\&gt;\&#xd;\
\&#xd;\
</description>\
      <filterExecutors>false</filterExecutors>\
      <filterQueue>false</filterQueue>\
      <properties class=\"hudson.model.View\$PropertyList\"/>\
      <jobNames class=\"tree-set\">\
        <comparator class=\"hudson.util.CaseInsensitiveComparator\"/>\
      </jobNames>\
      <jobFilters/>\
      <columns>\
        <hudson.views.StatusColumn/>\
        <hudson.plugins.favorite.column.FavoriteColumn/>\
        <hudson.views.WeatherColumn/>\
        <com.robestone.hudson.compactcolumns.JobNameColorColumn>\
          <colorblindHint>nohint</colorblindHint>\
          <showColor>true</showColor>\
          <showDescription>true</showDescription>\
          <showLastBuild>true</showLastBuild>\
        </com.robestone.hudson.compactcolumns.JobNameColorColumn>\
        <jenkins.plugins.extracolumns.ConfigureProjectColumn/>\
        <hudson.plugins.CronViewColumn/>\
        <com.robestone.hudson.compactcolumns.AllStatusesColumn>\
          <colorblindHint>nohint</colorblindHint>\
          <timeAgoTypeString>DIFF</timeAgoTypeString>\
          <onlyShowLastStatus>false</onlyShowLastStatus>\
          <hideDays>0</hideDays>\
        </com.robestone.hudson.compactcolumns.AllStatusesColumn>\
        <jenkins.plugins.extracolumns.TestResultColumn/>\
        <org.jenkins.ci.plugins.column.console.LastBuildColumn/>\
        <hudson.plugins.projectstats.column.NumBuildsColumn/>\
        <hudson.views.BuildButtonColumn/>\
      </columns>\
      <includeRegex>${projectName}-.*</includeRegex>\
      <useCssStyle>false</useCssStyle>\
      <includeStdJobList>true</includeStdJobList>\
      <leftPortletWidth>50%</leftPortletWidth>\
      <rightPortletWidth>50%</rightPortletWidth>\
      <leftPortlets>\
        <hudson.plugins.view.dashboard.stats.StatBuilds>\
          <id>dashboard_portlet_9</id>\
          <name>Build statistics</name>\
        </hudson.plugins.view.dashboard.stats.StatBuilds>\
        <hudson.plugins.dry.dashboard.WarningsTablePortlet>\
          <id>dashboard_portlet_10</id>\
          <name>Duplicate code per project</name>\
          <canHideZeroWarningsProjects>false</canHideZeroWarningsProjects>\
        </hudson.plugins.dry.dashboard.WarningsTablePortlet>\
        <hudson.plugins.pmd.dashboard.WarningsTablePortlet>\
          <id>dashboard_portlet_11</id>\
          <name>PMD warnings per project</name>\
          <canHideZeroWarningsProjects>false</canHideZeroWarningsProjects>\
        </hudson.plugins.pmd.dashboard.WarningsTablePortlet>\
      </leftPortlets>\
      <rightPortlets>\
        <hudson.plugins.view.dashboard.test.TestStatisticsChart>\
          <id>dashboard_portlet_12</id>\
          <name>Test Statistics Chart</name>\
        </hudson.plugins.view.dashboard.test.TestStatisticsChart>\
        <hudson.plugins.view.dashboard.test.TestStatisticsPortlet>\
          <id>dashboard_portlet_13</id>\
          <name>Test Statistics Grid</name>\
        </hudson.plugins.view.dashboard.test.TestStatisticsPortlet>\
        <hudson.plugins.cobertura.dashboard.CoverageTablePortlet>\
          <id>dashboard_portlet_14</id>\
          <name>Code Coverages</name>\
        </hudson.plugins.cobertura.dashboard.CoverageTablePortlet>\
        <hudson.plugins.release.dashboard.RecentReleasesPortlet>\
          <id>dashboard_portlet_15</id>\
          <name>Recent Releases</name>\
        </hudson.plugins.release.dashboard.RecentReleasesPortlet>\
      </rightPortlets>\
      <topPortlets/>\
      <bottomPortlets>\
        <hudson.plugins.analysis.collector.dashboard.WarningsTablePortlet>\
          <id>dashboard_portlet_16</id>\
          <name>Warnings per project</name>\
          <canHideZeroWarningsProjects>false</canHideZeroWarningsProjects>\
          <useImages>false</useImages>\
          <isCheckStyleDeactivated>false</isCheckStyleDeactivated>\
          <isDryDeactivated>false</isDryDeactivated>\
          <isFindBugsDeactivated>false</isFindBugsDeactivated>\
          <isPmdDeactivated>false</isPmdDeactivated>\
          <isOpenTasksDeactivated>false</isOpenTasksDeactivated>\
          <isWarningsDeactivated>false</isWarningsDeactivated>\
        </hudson.plugins.analysis.collector.dashboard.WarningsTablePortlet>\
      </bottomPortlets>\
    </hudson.plugins.view.dashboard.Dashboard>"
   addJenkinsView "$projectJenkinsView"
   sed -i s:"<primaryView>.*":"<primaryView>${projectName}</primaryView>":g $PROJECT_HOME/app/jenkins/config.xml

}

function addPipelineView(){
   addJenkinsPipelineView
}

function commonTasksInJob(){
   originalJob=$1
   moduleName=$2
   fullJobName=$3
   newJobDir=$JOBS_DIR/$fullJobName
   rm -Rf $newJobDir
   cp -R $originalJob $newJobDir
   sed -i s:"PROJECTTEMPLATE-MODULETEMPLATE-":"${projectName}-${moduleName}-":g $newJobDir/config.xml
   sed -i s:"PROJECTTEMPLATE":"${projectName}":g $newJobDir/config.xml
   local thisHost
   host $(hostname) >/dev/null
   if [ "$?" != 0 ]; then
      thisHost=$(hostname)
   else
      thisHost=$(host `hostname`|head -1|cut -d' ' -f1)
   fi
   sed -i s:"HOST_PIPELINE":"${thisHost}":g $newJobDir/config.xml
   sed -i s:"MODULETEMPLATE":"${moduleName}":g $newJobDir/config.xml
   sed -i s:"<url>\.\./\.\./\.\./sites/":"<url>http\://$develenvHost/sites/":g $newJobDir/config.xml
   if [ "$n" == "1" ]; then
      if [ $moduleName != "ALL" -a $moduleName != "EXPORT" ]; then
         addPipelineView
       fi
   fi
}

function addPipelineJob(){
   filter=$1
   moduleName=$2
   n=0
   for i in `find -maxdepth 1 -name "PROJECTTEMPLATE-${filter}-*"|sort`;do
      n=`expr $n + 1`
      jobName=`echo $i|cut -d'-' -f4`
      numberJobName=`echo $i|cut -d'-' -f3`
      fullJobName=$projectName-$moduleName-$numberJobName-$jobName
      commonTasksInJob "$i" $moduleName $fullJobName
   done;
}

function addExportJob(){
   fullJobName=$projectName-EXPORT
   commonTasksInJob "PROJECTTEMPLATE-EXPORT" EXPORT $fullJobName
}

function addCommonJobs(){
   moduleName=$1
   addJenkinsProjectView
   addPipelineJob "ALL" "$moduleName"
   addExportJob
}

function addSpecificModuleJobs(){
   moduleName=$1
   addPipelineJob "MODULETEMPLATE" "$moduleName"
}

function helpParameter(){
   help=`echo $*|grep "\-\-help"`
   if [ -n "$help" ]; then
      help
      exit 0
   fi
}

function testCreateModuleParameters(){
   helpParameter $*
   if [ $# != "2" ]; then
      errorParameters "Incorrect number of parameters"
   fi
   projectName=$1
   module=$2
   if ! [[ $projectName =~ $standardParameterREGEX ]] ; then
       errorParameters "[$projectName] Incorrect project name  parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
   fi
   if ! [[ $module =~ $standardParameterREGEX ]] ; then
       errorParameters "[$module] Incorrect module parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
   fi
}


function createModule(){
   moduleName=$2
   projectName=$1
   scmMessage="${projectName}-ALL-02-smokeTest ${projectName}-ALL-03-acceptanceTest ${projectName}-${moduleName}-01-build"
   testCreateModuleParameters $projectName $moduleName
   _message "Creating module $2  in $projectName project"
   cd $MODULE_TEMPLATE_DIR/jobs
   addSpecificModuleJobs $moduleName
   cd $JOBS_DIR
   if [ -z "`find -maxdepth 1 -name \"${projectName}-ALL-*\"`" ]; then
      cd $MODULE_TEMPLATE_DIR/jobs
      addCommonJobs "ALL"
   fi
   reloadJenkinsMessage
   configureSCMJobMessage "${scmMessage}"
}

function addModule(){
   projectName=$1
   moduleName=$2
   createModule $projectName $moduleName
}

function isCreatedProject(){
   projectName=$1
   cd $JOBS_DIR
   if ! [ -z "`find -maxdepth 1 -name \"${projectName}-ALL-*\"`" ]; then
      _log "[ERROR] Project [${projectName}] already exits."
      exit 1
   fi
   cd -
}

function errorParameters(){
   _log "[ERROR] $1"
   help
   exit 2

}

function testCreateProjectParameters(){
   helpParameter $*
   if [ $# != "6" ]; then
      errorParameters "Incorrect number of parameters"
   fi
   organization=$1
   projectName=$2
   versionProject=$3
   modules=$4
   enviroments="$5"
   adminUser=$6
   if ! [[ $organization =~ $standardParameterREGEX ]] ; then
       errorParameters "[$organization] Incorrect organization parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
   fi
   if ! [[ $projectName =~ $standardParameterREGEX ]] ; then
       errorParameters "[$projectName] Incorrect project name  parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
   fi
   if ! [[ $versionProject =~ $versionParameterREGEX ]] ; then
       errorParameters "[$versionProject] Incorrect version number parameter.This parameter doesn't match with [$versionParameterREGEX] expresion"
   fi
   for module in $modules; do
      if ! [[ $module =~ $standardParameterREGEX ]] ; then
       errorParameters "[$module] Incorrect module parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
      fi
   done;
   for enviroment in $enviroments; do
      if ! [[ $enviroment =~ $standardParameterREGEX ]] ; then
       errorParameters "[$module] Incorrect enviroment parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
      fi
   done;
   if ! [[ $adminUser =~ $standardParameterREGEX ]] ; then
       errorParameters "[$adminUser] Incorrect adminUser  parameter. This parameter doesn't match with [$standardParameterREGEX] expresion"
   fi
}

function sustituteConfigJob(){
   configFile=$1
   filterString=$2
   filterSubstitute=$3
   deploymentLine=`cat $configFile|grep -n "$filterString"|cut -d":" -f1`
   head -n $(expr $deploymentLine - 1 ) $configFile > ${configFile}.tmp
   echo -e  $filterSubstitute  >> ${configFile}.tmp
   sed 1,${deploymentLine}d ${configFile} >> ${configFile}.tmp
   mv ${configFile}.tmp ${configFile}
}

function createProject(){
   organization="$1"
   projectName="$2"
   versionProject="$3"
   modules="$4"
   enviroments="$5"
   adminUser="$6"
   local machineEnviroment
   testCreateProjectParameters  "$organization" "$projectName" \
"$versionProject" "$modules" "$enviroments" "$adminUser"
   isCreatedProject $projectName
   #Se borran los ficheros creados en la ejecución anterior
   rm -Rf $NEXT_STEPS_FILE
   for module in $modules; do
      addModule $projectName $module
   done;
   deploymentTestTable="#!/bin/bash\n\
#export DEBUG_PIPELINE=\"TRUE\"\n\
. pipeline.sh\n\
\n\
##################### DEPLOYMENT TABLE ############################\n\
#WARNING: No borrar la línea anterior, ya que es el separador\n\
#         del script y de la DEPLOYMENT TABLE\n\
\n\
\n\
\n\
############################### WARNING #########################################\n\
# La tabla siguiente ha sido creada automáticamente a partir de la ejecución    #\n\
# del script /opt/ss/develenv/dp/admin/pipelineProject.sh                       #\n\
# Revise la configuración de dicha tabla                                        #\n\
# Para mas info http://code.google.com/p/develenv-pipeline-plugin               #\n\
#################################################################################\n\
#--------------+------------------------------------\n\
# Enviroment   | URL                                \n"

   deploymentTable="#!/bin/bash\n\
#export DEBUG_PIPELINE=\"TRUE\"\n\
. pipeline.sh\n\
\n\
##################### DEPLOYMENT TABLE ############################\n\
#WARNING: No borrar la línea anterior, ya que es el separador\n\
#         del script y de la DEPLOYMENT TABLE\n\
\n\
\n\
\n\
############################### WARNING ###########################################\n\
# La tabla siguiente ha sido creada automáticamente a partir de la ejecución      #\n\
# del script /opt/ss/develenv/dp/admin/pipelineProject.sh.                        #\n\
# Revise la configuración de dicha tabla                                          #\n\
# Para mas info http://code.google.com/p/develenv-pipeline-plugin                 #\n\
###################################################################################\n\
# Organization: $organization \n\
# Project: $projectName\n\
# Version: $versionProject\n\
# Enviroments: $enviroments\n\
# AdminUser: $adminUser\n\
#--------------+------------------------------------+--------------------------------------------------\n\
# Enviroment   | IPs/Hosts                          | Packages\n\
#--------------+------------------------------------+--------------------------------------------------\n"
   _message "Creating $projectName ..."
   configureEnviroments=""
   for enviroment in $enviroments; do
      configureEnviroments="$configureEnviroments<string>$enviroment</string>"
      machineEnviroment=$(echo ${enviroment}-${projectName}-01|tr '[A-Z]' '[a-z]')
      line="$enviroment | ${machineEnviroment} |"
      lineTest="$enviroment | http://${machineEnviroment}"
      for module in $modules; do
         line="$line ${organization}-${projectName}-${module}"
      done;
      deploymentTable="${deploymentTable}${line}\n"
      deploymentTestTable="${deploymentTestTable}${lineTest}\n"
   done;
   installJobFile=$PROJECT_HOME/app/jenkins/jobs/${projectName}-ALL-01-install/config.xml
   sustituteConfigJob "$installJobFile" "INSTALL_DEPLOYMENT_PIPELINE" "$deploymentTable"
   sustituteConfigJob "$PROJECT_HOME/app/jenkins/jobs/${projectName}-ALL-02-smokeTest/config.xml" "TEST_DEPLOYMENT_PIPELINE" "$deploymentTestTable"
   sustituteConfigJob "$PROJECT_HOME/app/jenkins/jobs/${projectName}-ALL-03-acceptanceTest/config.xml" "TEST_DEPLOYMENT_PIPELINE" "$deploymentTestTable"
   sed -i s:"<string>PROJECTENVIROMENT</string>":"${configureEnviroments}":g ${installJobFile}
   ADD_MODULE_TO_PIPELINE_JOB="pipeline-ADMIN-02-addModuleToPipeline"
   if ! [ -d $PROJECT_HOME/app/jenkins/jobs/${ADD_MODULE_TO_PIPELINE_JOB} ]; then
      mkdir -p $PROJECT_HOME/app/jenkins/jobs/${ADD_MODULE_TO_PIPELINE_JOB}/
      sed s:"PIPELINE_PROJECT_ID":"$projectName":g $MODULE_TEMPLATE_DIR/adminJobs/${ADD_MODULE_TO_PIPELINE_JOB}/config.xml > $PROJECT_HOME/app/jenkins/jobs/${ADD_MODULE_TO_PIPELINE_JOB}/config.xml
   else
      sed -i s:"<a class=\"string-array\">":"<a class=\"string-array\"><string>$projectName</string>":g  $PROJECT_HOME/app/jenkins/jobs/${ADD_MODULE_TO_PIPELINE_JOB}/config.xml
   fi
   reloadJenkinsMessage
}

init

