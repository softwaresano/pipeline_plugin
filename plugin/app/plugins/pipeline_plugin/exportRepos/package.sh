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

function markdown2html(){
   cp $DP_HOME/exportRepos/pom.xml .
   cp $DP_HOME/exportRepos/src/site/site.xml \
      src/site
   mvn site:site
   cp target/site/README.html target/site/index.html
}

function postPackage() {
   local dir_repo
   local def_repo
   local fileName
   local rpmName
   local readmeMdFile
   local onlyFileName
   fileName="$DEVELENV_HOME/app/repositories/rpms/noarch/${rpm_name}.noarch.rpm"
   rpmName=`basename $fileName`
   rm -Rf target && mkdir -p target/site
   outputFile="target/site/${rpmName}.sh"
   echo "#!/bin/bash" > ${outputFile}
   size=`ls -Al ${fileName}|awk '{print $5}'`
   echo "size=$size" >> ${outputFile}
   echo "tail -c $size \$0 >$rpmName" >>${outputFile}
   echo 'if  [ `id -un` != "root" ]; then'  >>${outputFile}
   echo "   echo '[ERROR] Sólo root puede lanzar ${rpmName}.sh'" >>${outputFile}
   echo "   exit 1" >>${outputFile}
   echo "fi" >>${outputFile}
   echo "rpm -Uvh $rpmName" >>${outputFile}
   echo 'if  [ "$?" != "0" ]; then' >>${outputFile}
   echo "    echo '[ERROR] Imposible instalar $rpmName'" >>${outputFile}
   echo "   exit 1" >>${outputFile}
   echo "fi" >>${outputFile}
   echo "rm -Rf $rpmName" >>${outputFile}
   echo "exit 0" >> ${outputFile}
   echo "#### install ####" >> ${outputFile}
   cat ${fileName} >>${outputFile}
   chmod 755 $outputFile
   dir_repo=$(rpm -qlp $fileName |grep "rpm"|head -1|sed s:"repo/.*":"repo":g)
   def_repo=$(rpm -qlp $fileName |grep "yum\.repos\.d.*\.repo$")
   readmeMdFile="src/site/markdown/README.md"
   onlyFileName=$(basename ${outputFile})
   rm -Rf $(dirname "$readmeMdFile")
   mkdir -p $(dirname "$readmeMdFile")
   echo "
EXPORTACIÓN REPOSITORIO RPMS
============================


El script [${onlyFileName}](${onlyFileName}) contiene el 
repositorio con todos los paquetes para instalar el producto. 
Después de la ejecución de éste script todos los paquetes estarán disponibles 
para su instalación en el directorio **${dir_repo}** y serán 
instalables a partir del comando *dnf install <nombre_paquete>* ya que se ha 
configurado el acceso a los repos en **${def_repo}**


Instalación Repositorio
-----------------------

Para instalar el repositorio:

* Copiar el fichero [${onlyFileName}](${onlyFileName})  en 
la máquina donde se vaya a instalar el repositorio
* Dar permisos de ejecución a [${onlyFileName}](${onlyFileName})

\`\`\`
   chmod u+x ${onlyFileName}
\`\`\`
* Ejecuta el script como *root* o como administrador *sudoer*

\`\`\`
   ./${onlyFileName}
\`\`\`
* Para comprobar que se ha instalado en la máquina. Ejecuta:

\`\`\`
   rpm -qa|grep "$rpmName"
\`\`\`
Instalación de paquetes del repositorio
---------------------------------------

Para instalar un paquete. Por ejemplo (`basename $(rpm -qlp $fileName|grep \"\.rpm\"|head -1)|sed s:\"\.rpm$\":\"\":g`) 

\`\`\`
   dnf install `basename $(rpm -qlp $fileName|grep \"\.rpm\"|head -1)|sed s:\"\.rpm$\":\"\":g`
\`\`\`

Paquetes que contiene el repositorio
------------------------------------

\`\`\`" > ${readmeMdFile}
   rpm -qlp $fileName|grep -v "repodata"|grep "\.rpm" >> ${readmeMdFile}
   echo "\`\`\`" >> ${readmeMdFile}
   markdown2html
   #Formato txt
   echo "${outputFile} contiene el repositorio con todos los paquetes para instalar el producto." > target/README.txt
   echo "" >> target/README.txt
   echo "" >> target/README.txt
   echo "Para instalar el repositorio:" >> target/README.txt
   echo "   * Copiar el fichero ${outputFile} en la máquina donde se vaya a instalar el repositorio" >> target/README.txt
   echo "   * Dar permisos de ejecución a  ${outputFile}" >> target/README.txt
   echo "      chmod u+x ${outputFile}" >> target/README.txt
   echo "   * Ejecuta el script como root" >> target/README.txt
   echo "   * Para comprobar que se ha instalado en la máquina. Ejecuta:" >> target/README.txt
   echo "      rpm -qa|grep \"$rpmName\"" >> target/README.txt
   echo "Para instalar un paquete: 
   Ejemplo:
      dnf install `basename $(rpm -qlp $fileName|grep \"\.rpm\"|head -1)|sed s:\"\.rpm$\":\"\":g`
   " >> target/README.txt
   echo "Los paquetes contenidos en este repositorio son:" >> target/README.txt
   rpm -qlp $fileName|grep -v "repodata"|grep "\.rpm" >> target/README.txt
   return;
}

function main(){
   local repoName
   local org_acronym
   org_acronym=$(grep "^# Organization: " $DEVELENV_HOME/app/jenkins/jobs/${INSTALL_JOB_ID}/builds/${installBuildId}/archive/target/DEPLOYMENT_PIPELINE/deployment.txt|sed s:".*\:":"":g|awk '{print $1}')
   [ "$org_acronym" == "" ] && org_acronym="$DEFAULT_PREFIX_ORGANIZATION"
   repoName=$(grep "^# Project: " $DEVELENV_HOME/app/jenkins/jobs/${INSTALL_JOB_ID}/builds/${installBuildId}/archive/target/DEPLOYMENT_PIPELINE/deployment.txt|sed s:".*\:":"":g|awk '{print $1}')
   [ "$repoName" == "" ] && repoName=$(echo $JOB_NAME|sed s:"-EXPORT$":"":g)
   sed s:"^Name\:.*":"Name\: repo\\n%define _org_acronym $org_acronym\\n%define _repoName $repoName\\n%define packagesVersionFile $DEVELENV_HOME/app/jenkins/jobs/${INSTALL_JOB_ID}/builds/${installBuildId}/archive/target/DEPLOYMENT_PIPELINE/packageVersionsInstalled.txt":g $DP_HOME/exportRepos/src/main/rpm/SPECS/repo.template>repo.spec
   . $DP_HOME/profiles/package/redhat/dp_package.sh
   #The name of rpm is $org_acronym-$repoName-$version-$release.noarch.rpm
   execute --version $2 --release $3 --project $repoName --organization $org_acronym
}

main --debug $*