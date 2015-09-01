#!/bin/bash
function currentDir(){
   DIR=`readlink -f $0`
   DIR=`dirname $DIR`
}

currentDir
. $DIR/setEnv.sh
addJenkinsView(){
   view=$1
   sed -i s:"</views>":"$view</views>":g $PROJECT_HOME/app/jenkins/config.xml
}

addJenkinsProjectView(){
   projectJenkinsView="    <hudson.plugins.view.dashboard.Dashboard>\
      <owner class=\"hudson\" reference=\"../../..\"/>\
      <name>Admin pipelines</name>\
      <description>Admin deployment pipelines</description>\
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
        <com.robestone.hudson.compactcolumns.AllStatusesColumn>\
          <colorblindHint>nohint</colorblindHint>\
          <timeAgoTypeString>DIFF</timeAgoTypeString>\
          <onlyShowLastStatus>false</onlyShowLastStatus>\
          <hideDays>0</hideDays>\
        </com.robestone.hudson.compactcolumns.AllStatusesColumn>\
        <org.jenkins.ci.plugins.column.console.LastBuildColumn/>\
        <hudson.plugins.projectstats.column.NumBuildsColumn/>\
        <hudson.views.BuildButtonColumn/>\
      </columns>\
      <includeRegex>pipeline-ADMIN-.*</includeRegex>\
      <useCssStyle>false</useCssStyle>\
      <includeStdJobList>true</includeStdJobList>\
      <leftPortletWidth>50%</leftPortletWidth>\
      <rightPortletWidth>50%</rightPortletWidth>\
      <leftPortlets/>\
      <rightPortlets/>\
      <topPortlets/>\
      <bottomPortlets/>\
    </hudson.plugins.view.dashboard.Dashboard>"
   addJenkinsView "$projectJenkinsView"
}

installRedHat(){
  pushd . >/dev/null

  popd >/dev/null

}

installDebian(){
  pushd . >/dev/null

  popd >/dev/null

 }

installCommon(){
  pushd . >/dev/null
  addJenkinsProjectView

  popd >/dev/null
}

name=`basename pipeline_plugin.sh|cut -d'.' -f1`
installationIn$distribution
install$distribution
installCommon

