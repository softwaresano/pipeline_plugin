#!/bin/bash
[ -z "$DP_HOME" ] && echo "[ERROR] DP_HOME must be defined" && exit 1

if [ "$DEBUG_PIPELINE" == "TRUE" ]; then
   set -x
else
   set +x
fi

source $DP_HOME/dp_setEnv.sh
source $SET_ENV_FILE
# Variables to erase!!
PROJECT_NAME=PythonExample
buildProjectType=python

function check_remote_file(){
   URL=$1
   wget --spider -v $URL
   if [ $? -gt 0 ]; then
      _log "[ERROR] Can't obtain metric file $URL"
      return 1 
   else
      return 0
   fi
}

# función para bajarse los xmls de las métricas
function obtain_xmls () {
   mkdir -p tmp
   local url="http://ci-pipeline/sonar/api/resources?resource=com.softwaresano.develenv.$PROJECT_NAME&metrics=coverage,ncloc,duplicated_lines_density&format=json"
   if check_remote_file $url; then
      curl -s -o tmp/$PROJECT_NAME.metrics.json $url
   else
      return 1
   fi

   # Types suppported: maven, ant, staticWeb, python
   case $buildProjectType in
      python)
         url="http://ci-pipeline.hi.inet/sonar/api/violations?resource=com.softwaresano.develenv.$PROJECT_NAME&depth=-1&rules=python:FunctionComplexity&format=xml"
         if check_remote_file $url; then
            wget -q -O tmp/$PROJECT_NAME.cc.xml $url
         else
            return 1
         fi
         ;;
      maven|ant)
         url="http://ci-pipeline.hi.inet/sonar/api/violations?resource=com.softwaresano.develenv.$PROJECT_NAME&depth=-1&rules=squid:MethodCyclomaticComplexity&format=xml"
         if check_remote_file $url; then
            wget -q -O tmp/$PROJECT_NAME.cc.xml $url
         else
            return 1
         fi
         ;;
      staticWeb)
         ;;
   esac
   return 0
}



function extractMetrics(){
    _log "[INFO]Extracting metrics..."
   mkdir -p ../metrics
   if [ ! -f ../metrics/history ]; then
      touch ../metrics/history
      echo "1970-01-01,0,0,0,0,0" > ../metrics/history
   fi

   _log "Obtaining XMLs..."
   obtain_xmls
   _log "XMLs Obtained, Extracting results..." 
   # New way
   local date=`date +%Y-%m-%d`
   local ncloc=`cat tmp/$PROJECT_NAME.metrics.json | python3 -c 'from simplejson.tool import main; main()' | \
                         grep -A1 ncloc | grep val | awk '{ print $2 }'`
   local dupes=`cat tmp/$PROJECT_NAME.metrics.json | python3 -c 'from simplejson.tool import main; main()' | \
                         grep -A1 duplicated_lines_density | grep val | awk '{ print $2 }'`
   local coverage=`cat tmp/$PROJECT_NAME.metrics.json | python3 -c 'from simplejson.tool import main; main()' | \
               grep -A1 coverage | grep val | awk '{ print $2 }'`
   #do_metrics_extract
      local cC=`cat tmp/$PROJECT_NAME.cc.xml | sed s:"</violation>":"&\r\n":g | grep -v violations | wc -l`
   build_success=1

   # Añadir las métricas solo si:
   # nloc - no se comprueba (natural)
   # dupes - 1% de margen (decimal)
   # coverage - 1 % de margen (decimal)
   # cC >9 /100 loc  0.1 margen (decimal)
   # Build_success-  no se comprueba
   echo $date,$ncloc,$dupes,$coverage,$cC,$build_success >> ../metrics/history
   return 0;
# $WORKSPACE/../metrics/history
#Date,ncloc,duplications,coverage,cc,build_success
#------------------------------------------------
#2012-11-22,456,23%,12%,22,45%
}


function areMetricsOk(){
    _log "Checking metrics..."
    metricsOk=0
    prev_lines=`tail -n2 ../metrics/history | head -n1`
    last_lines=`tail -n1 ../metrics/history`
    local margin="1.0"

    for a in `seq 2 6`; do 
      if [ "$metricsOk" == 1 ]; then
                  return 1
      fi
      case $a in
                  # codeComplexity
                  5)
                     met1=`cat $prev_lines | cut -d, -f$a`
                met2=`cat $last_lines | cut -d, -f$a`
                     if [ met1 -gt met2 ]; then
                        metricsOk=1
                     fi
                     ;;
                  # dupes 1% margin accepted (+/-)
                  3)
                     met1=`cat $prev_lines | cut -d, -f$a`
               met2=`cat $last_lines | cut -d, -f$a`
                     met3=`echo $met1 - met2 | bc`
                     if [ "met3" -gt "margin" -o  met1 -gt mett2 ]; then
                                 metricsOk=1
                     fi
                     ;;
                  # coverage 1% margin accepted (+/-)
                  4)
                     met1=`cat $prev_lines | cut -d, -f$a`
               met2=`cat $last_lines | cut -d, -f$a`
                     met3=`echo $met1 - met2 | bc`
                     if [ "met3" -gt "margin" -o met1 -lt mett2 ]; then
                                 metricsOk=1
                     fi
                     ;;
                  *)
                   ;;
    esac
    done
   return $metricsOk;
}

if [ -f ../metrics/sonar ]; then
    exit 0
   extractMetrics
   [[ $? == 0 ]] && areMetricsOk 
fi

exit 0
