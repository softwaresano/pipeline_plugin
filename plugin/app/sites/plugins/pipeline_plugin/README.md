DEPLOYMENT PIPELINE
=====================

* [Introducción] (#introducciÓn)
* [Instalación] (#instalaciÓn)
* [Definición Pipeline] (#definiciÓn-de-un-pipeline)
* [Primeros Pasos] (#primeros-pasos)
* [Ejecución] (#ejecuciÓn)
* [Limitaciones del pipeline] (#limitaciones-del-pipeline)
* [How to cotribute to Deployment pipeline]

INTRODUCCIÓN
------------
Cada vez que se realice un cambio en el software(commit en el repositorio) debería poder ser instalado en cualquier
entorno. Para ello es necesario disponer de un panel con los diferentes builds que se han generado del proyecto y en que
en qué entornos ha sido o puede ser instalado. 

![Ejemplo Pipeline]( http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/01_pipelineDashBoard.png "Ejemplo Pipeline")

Mediante la utilización **deployment pipeline plugin** se pretende evitar problemas en la instalación de un entorno nuevo, 
puesto que el proceso de instalación del software se tiene en cuenta desde el principio.


INSTALACIÓN
-----------

La deployment pipeline viene instalada con ![develenv] (http://develenv.softwaresano.com). Para
utilizarla fuera de [develenv] (http://develenv.softwaresano.com) se puede hacer:

  * Utilizando el rpm que está disponible en el repositorio de develenv: 
`dnf install ss-develenv-dp`
  * Descargando los fuentes directamente los fuentes
`svn co http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/plugins/pipeline_plugin
 cd pipeline_plugin
 export PATH=$PWD:$PATH
`

DEFINICIÓN DE UN PIPELINE
-------------------------

Todo el pipeline está dirigido por jobs de Jenkins. El nombrado de los jobs servirá al pipeline para ejecutar
los scripts correspondientes a cada fase del pipeline. Así el nombre de un job está formado por

[projectName]-[module]-[order]-[phase]. Donde:

* **proyectName**: Es el identificador del proyecto
* **module**: Módulo del proyecto (Ej. frontend ,backend). Existen 2 módulos especiales:
 * ALL: Identifica una tarea que se ha de ejecutar con los diferentes módulos del proyecto. (Por ejemplo install, 
 smokeTest, y acceptanceTest se ejecutarán después de que haya un cambio en alguno de los módulos)
 * EXPORT: Exporta el repositorio de componentes(actualmente sólo rpms) a un fichero para poderlo copiar en una máquina en la que no tenemos acceso actualmente.
* **order**: Es ún número de 2 cifras cuya única misión es que aparezcan ordenados los jobs en el pipeline según su 
orden de ejecución.
* **phase**: Fase de ejecución del pipeline. Estas fases son (build, package, install, smoketest, acceptanceTest)

Habrá varios tipos de jobs,

  * [Pre-deploy (Un job por cada fase y componente)](#pre-deploy-jobs)
   * [Build (compile, unit Test, integration Test, Metrics)(Developer)](#build)
   * [Package (dependendiente del S.O) (Release Engineer)](#package)
  * [Deploy  (Un job común por fase para todos los componentes)](#deploy-jobs)
   * [Install (Release Engineer)](#install)
  * [Post-deploy (Un job común por fase para todos los módulos)](#post-deploy-jobs)
   * [Smoke Tests (Comprobar mínimimamente que funcionan cada uno de los módulos) (Release Engineer)](#smoke-test)
   * [Acceptance Tests (QA Engineer)](#acceptance-test)
         
Pre-deploy Jobs
---------------
   Este tipo de jobs se debe crear uno por cada componente del proyecto. 
   (En el ejemplo de hay un job para el backend y otro para el frontend).
   
   A partir de un commit en un repositorio se han de ejecutar una serie de pasos(pueden ser todos en el mismo job). 
   El objetivo final es generar un paquete para ser instalado en el S.O, en este caso un rpm.
   
### Build
El objetivo de este job es generar los objetos que se utilizarán en la fase de [package](#package). Por ejemplo si se desarrolla
una apliación web, la salida de este job debería ser un fichero  **.war** y los ficheros de configuración necesarios
para poder configurar la aplicación en cualquier entorno conocido.

Cuando se ejecute este job se buscará inicialmente un script [build.sh](http://pimpam.googlecode.com/svn/trunk/webCalculator-backend/build.sh "build.sh") en la raíz del proyecto. 
Si no se encuentra entonces se ejecutará el script [dp_build.sh](http://code.google.com/p/develenv-pipeline-plugin/source/browse/trunk/pipeline_plugin/plugin/app/plugins/pipeline_plugin/dp_package.sh "dp_build.sh") 
que integra este plugin

### Package
Generará el paquete (actualmente sólo rpm) a partir de los objetos generados en la fase de [build](#build)

Cuando se ejecute este job se buscará inicialmente un script **package.sh** en la raíz del proyecto. Si no se encuentra
entonces se ejecutará el script [dp_package.sh](http://code.google.com/p/develenv-pipeline-plugin/source/browse/trunk/pipeline_plugin/plugin/app/plugins/pipeline_plugin/dp_package.sh "dp_package.sh") 
que integra este plugin
 
   
Deploy Jobs
-----------
   El objetivo de este tipo de jobs es desplegar el proyecto completo en un entorno determinado. 
   
### Install
   
   En este Job se define la tabla de despliegue. Esta tabla recoge la información de que componentes
   hay instalados en cada una de las máquinas que forman un entorno.

```
##################### DEPLOYMENT TABLE ############################
# Organization: ss
# Project: webCalculator
# Enviroments: continous-int qa preproduction production
#--------------+------------------------------------+--------------------------------------------------
# Enviroment   | IPs/Hosts                          | Packages
#--------------+------------------------------------+--------------------------------------------------
continous-int  | ci-emc2-xp                         | ss-webCalculator-backend ss-webCalculator-frontend
qa             | ci-conelect                        | ss-webCalculator-backend ss-webCalculator-frontend
preproduction  | connect-ci                         | ss-webCalculator-backend ss-webCalculator-frontend
production     | wcbackend1.bigdata.hi.inet         | ss-webCalculator-backend
production     | wcbackend2.bigdata.hi.inet         | ss-webCalculator-backend
production     | wcfrontend.bigdata.hi.inet         | ss-webCalculator-frontend
```

   Para crear un nuevo pipeline, replicar este Job y configurar únicamente la deployment Table
   
   
### Smoke 
   Este job comprueba que hay connectividad entre los diferentes componentes que forman el proyecto. 
   El tipo de tests que debe ejecutar no deberían alterar el estado del proyecto (p.ej no deberían escribir en la DB).
   
   Cuando se ejecute este job se buscará inicialmente un script [smokeTest.sh](http://pimpam.googlecode.com/svn/trunk/webCalculator-smokeTest/smokeTest.sh) 
   en la raíz del proyecto.
   
   [Ejemplo de SmokeTest](http://pimpam.googlecode.com/svn/trunk/webCalculator-smokeTest/smokeTest.sh)
   
   En el ejemplo sólo se hacen comprobaciones sobre peticiones http, para otro tipo de proyectos se deberían revisar el tipo
   de smokeTests que se realizan.
     
 

Post-Deploy Jobs
----------------

### Acceptance Test 
   Este job realiza las pruebas automáticas funcionales(End2End) de un entorno completo. 
   Cuando se ejecute este job se buscará inicialmente un script [acceptanceTest.sh](http://pimpam.googlecode.com/svn/trunk/webCalculator-acceptanceTest/acceptanceTest.sh) 
   en la raíz del proyecto.
   
   [Ejemplo de Acceptance Test](http://pimpam.googlecode.com/svn/trunk/webCalculator-acceptanceTest/acceptanceTest.sh)
 
 
Ejemplo:

   http://ci-rmtest/sites/pipelines/webCalculator/pipeline.html

PRIMEROS PASOS
--------------
Una vez [instalado](#instalaciÓn) el plugin, se deben seguir los siguientes pasos:

# Definición del pipeline
## ¿Qué entornos forman parte del pipeline?
   Definir el número de entornos donde se va a instalar el proyecto. Por ejemplo (ci, qa,thirdparty y demo)
## ¿Qué módulos?
   Módulos que forman el proyecto. Por ejemplo (frontend y backend)
# Creación del pipeline
   Toda la administración de los pipelines se puede hacer tanto por línea de de comandos, como a partir de jobs definidos
   en jenkins.
    
   * [ Línea de comandos ] (#creaci%C3%B3n-del-pipeline-línea-de-comandos)
   * [ Interfaz Gráfica ] (#creaci%C3%B3n-del-pipeline-interfaz-gr%C3%A1fica)

## Creación del pipeline (Línea de comandos)
```
carlosg@ironman:~$ sudo su - develenv
develenv@ironman:~$ cd /opt/ss/develenv/dp/admin
develenv@ironman:/opt/ss/develenv/dp/admin$ ./pipelineProject.sh --help
Uso: ./pipelineProject.sh <organization> <project-name> <version> <module [module]*> <enviroment [enviroment]*> [--help]
Creación del deployment pipeline de un proyecto


EJEMPLO:
    ./pipelineProject.sh "ss" "webCalculator" "1.0" "frontend backend" "ci qa thirdparty demo"

Más información en http://code.google.com/p/develenv-pipeline-plugin
develenv@ironman:/opt/ss/develenv/dp/admin$ ./pipelineProject.sh "ss" "webCalculator" "1.0" "frontend backend" "ci qa thirdparty demo"
[INFO] Reload jenkins configuration to aply the last changes (http://ironman/jenkins/reload).
develenv@ironman:/opt/ss/develenv/dp/admin$ # Para añadir un nuevo módulo se haría
develenv@ironman:/opt/ss/develenv/dp/admin$ ./pipelineModule.sh --help
Uso: ./pipelineModule.sh <project-name> <module>[--help]
Creación de un módulo dentro del deployment pipeline de un proyecto. Para crear un módulo es necesario que el proyecto esté creado anteriormente.


EJEMPLO:
    ./pipelineModule.sh "webCalculator" "admin" 
```

### Creación del pipeline (Interfaz Gráfica)
   
![Vista de administración de la pipeline](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/adminPipelineView.png
)
   Para crear un pipeline nuevo se ha de ejecutar el job **pipeline-ADMIN-01-addPipeline**. 
    
![Creación y configuración de un pipeline](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/addPipelineConfiguration.png
)
   
   
#### Configuración del pipeline

 Si la ejecución del job ha sido correcta. Se deben seguir los pasos indicados en el link **Next Steps** que aparece después
 de la creación del pipeline:
 
 * Reload Jenkins
 * Revisar tabla de despliegues
 * Exportar la clave pública del usuario develenv /home/develenv/.ssh/id_dsa.pub al usuario de root de las máquinas en la que accede el pipeline
 * Configurar repositorio de fuentes para develenv-ALL-02-smokeTest
 * Configurar repositorio de fuentes para develenv-ALL-03-acceptanceTest
 * Configurar repositorio de fuentes para develenv-kernel-01-build
 * Cada módulo puede tener dependencias de librerías, asegurarse que exite el job que genera el build para dichas librerías
 
 
 
![Creación correcta del pipeline](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/addPipelineOk.png
)
 
 Es necesario acabar de configurar los diferentes jobs de jenkins, para hacerlo puedes pinchar en el enlace "Next Steps" que ha aparecido en el menú de la izquierda

![Configuración jobs pipeline](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/addPipelineNextSteps.png
)

#### Recargar configuración de jenkins

Cuando se haya recargado la configuración de jenkins aparecerán nuevas vistas en jenkins. 

![Vista con todos los jobs asociados al pipeline](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/reloadJenkinsAllJobs.png)
![Vista con el pipeline del módulo de backend](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/webCalculatorBackendPipeline.png)
![Vista con el pipeline del módulo de frontend](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/webCalculatorFrontendPipeline.png)

#### Revisión de la tabla de despliegue

![Revisión tabla de despliegue](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/reviewDeploymentTable.png)

#### Exportar clave ssh de develenv a las máquinas del pipeline
![Exportar clave ssh de develenv](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/exportSshKey.png)

#### Configuración SCM de los diferentes jobs

![Configuración SCM frontend](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/configureScmFrontend.png)
![Configuración SCM backend](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/configureScmBackend.png)
![Configuración SCM smokeTest](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/configureScmSmokeTest.png)
![Configuración SCM acceptanceTest](http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/configureScmAcceptanceTest.png)
 
## NOTAS SOBRE LA CONFIGURACIÓN

 Después de la generación automática es muy importante revisar que toda la configuración que se ha generado de 
 forma automática es correcta:
 * Se ha creado una tabla de deployment automática en el job de **-ALL-01-install**, donde aparecen los nombres de las máquinas sin dominio.
 * Se ha creado una tabla de deployment automática en los jobs de **-ALL-02-smokeTest** y **-ALL-03-acceptanceTest**. Si se utilizan como plantilla los ejemplos de smokeTest y acceptanceTest anteriores, si se borra la deployment Table coge la deployment Table que hay entregada en el repositorio.

Hay que seguir extrictamente el formato de la deployment table para que la ejecución de los scripts de la pipeline
 no fallen. Por ejemplo no se puede eliminar la línea
 ```
 ##################### DEPLOYMENT TABLE ############################
 ```
 ya que esta línea es la que se utiliza como separador entre el script y la deployment table
 

EJECUCIÓN
---------
Cada vez que se haga un commit en alguno de los módulos que forman parte proyecto del pipeline se invocará el pipeline. Si
la construcción del build, el empaquetado y los tests son correctos el proyecto quedará instalado en el entorno de ci,
y listo para ser instalado en el siguiente entorno (por ejemplo en qa). En cada uno de los jobs que forman la pipeline
aparece el link **Deployment Pipeline** (http://ironman/sites/pipelines/webCalculator/pipeline.html) que apunta a una página del siguiente estilo.


![Deployment Report] (http://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/sites/plugins/pipeline_plugin/deploymentReport.png)



LIMITACIONES DEL PIPELINE
-------------------------
Actualmente este plugin está desarrollado para proyectos instalados bajos distribuciones Redhat/CentOS. 
Esto implica que cualquier componente de un proyecto debe estar paquetizado en formato rpm. Tal y como se 
ha desarrollado el pipeline permite una fácil extensión para otro tipo de distribuciones.

Para poder realizar la instalación en cada uno de los entornos, debe existir connectividad http y ssh entre la máquina 
donde está instalado develenv y cada una de las máquinas que forman el pipeline. Si no existe conectividad siempre existe 
la opción de exportar el repositorio (job EXPORT)

En cada paquete debe ir la configuración de los diferentes entornos. En el caso de que no se conozca la configuración o
no se desee poner dentro del paquete existen 2 posibilidades:
* Asegurarse que las máquinas disponen de la configuración correcta antes de realizar la instalación de los paquetes
* Realizarlo mediante Puppet

No se puede hacer un downgrade de un componente.

No se puede añadir un proyecto multiconfiguración de jenkins, por:
* Se ha de replicar el WS del proyecto padre con los diferentes hijos (solucionado)
* Después de la ejecución de cada hijo se debería invocar al siguiente job (Bloqueante). Solución ejecutar en el mismo job 
las diferentes configuraciones


DISCUSIóN
=========

PIPELINE-COMPLETO?? (Desde desarrollo a producción)
=================

Siempre que no tengamos la configuración exacta de cada uno de los entornos es muy arriesgado automatizar todo 
el proceso de configuración. Nos quedamos en la instalación del software, pero no en su configuración para los 
entornos de producción.


CONFIGURACIÓN-RPM vs PUPPET
===========================

Discusión

En el ejemplo todo está dentro de los rpms. En concreto
* Backend: En el caso del entorno de producción se ha abrir el puerto del conector AJP de tomcat
         http://pimpam.googlecode.com/svn/trunk/webCalculator-backend/src/main/rpm/SPECS/backend.spec
* Frontend: Si es producción se han de balancer las peticiones con los 2 backends.
         http://pimpam.googlecode.com/svn/trunk/webCalculator-frontend/src/main/rpm/SPECS/frontend.spec
         http://pimpam.googlecode.com/svn/trunk/webCalculator-frontend/src/main/rpm/SOURCES/enviroments/production/
   
HOW TO CONTRIBUTE TO DEPLOYMENT PIPELINE
----------------------------------------

- First of all, you need to [install develenv](http://develenv.softwaresano.com/installation.html) 
  with it comes the last pipeline_plugin version.
- You need to ask to Carlos (carlosegg@gmail.com) for access to the code repo, after this is done, then
- You need to authenticate as a develenv user in the installation machine, You can do this with a command like this:

```
# sudo su - develenv
```

- Go to the path $HOME/app/plugins/ and remove the pipeline_plugin dir:

```
$ cd ~/app/plugins
$ rm -rf pipeline_plugin
$ svn checkout https://develenv-pipeline-plugin.googlecode.com/svn/trunk/pipeline_plugin/plugin/app/plugins/pipeline_plugin/
```

- Then you have a live copy of the repository and can update it with your contributions.


¿QUÉ FALTA POR HACER?
======================
#### TODO --> Tener en cuenta paquetes de mock (se podrían gestionar como los paquetes de entorno)
#### TODO --> En una instalación controlar que se desinstalen paquetes que hayan quedados obsoletos (que no estén puestos en la tabla del pipeline, básicamente comprobar todos los paquetes que hay instalados y que empiecen por el prefijo ss-"
#### TODO --> En caso de que falle un job y se intente reejecutar, no hay que volver a clonar el repo.
#### TODO --> Externalizar el proceso de install para poder incluir puppet (revisar ya que hay algo implementado!!)
#### TODO --> Añadir ejemplos de build.sh ahora hay ejemplos de maven, ant, web estática(?) y python, faltaría los demás.
#### TODO --> Añádir ejemplos de package.sh para proyectos android, iphone y Windows (todos)
#### TODO --> Añadir ejemplos de acceptanceTest.sh para proyectos no Selenium ni Jmeter 
http://develenv.googlecode.com/svn/trunk/develenv/acceptanceTest.sh
#### TODO --> Añadir ejemplos de smokeTest.sh para controlar servicios específicos que no estén ya controlados por Nagios y que requieran un script (o agente) particular.
http://develenv.googlecode.com/svn/trunk/develenv/smokeTest.sh
#### TODO --> Revisar la clonación de los ws aunque la única forma segura de evitar colisiones en la DP es dedicando exclusivamente un ejecutor a la ejecución de la pipeline.
#### TODO --> Comprobar que funciona correctamente la actualización de este plugin
#### TODO --> Fijar los estados smokeTest-KO y acceptanceTest-KO (reutilizar el log que se utiliza para hacer el repo dp_changes.txt)
### TODO --> Puntos a tener en cuenta usando la pipeline y python:
  - Verificar que todos los proyectos python tienen un setup.py en la raíz del repo (u otra manera de identificarlos).
  - Modficar la detection de un proyecto django (*.wsgi)
  - Añadir la info de un proyecto Django
### TODO --> Mejorar dashboard añadiendo métricas por entorno, esta a medias se puede ver un ejemplo en:http://ci-myhealth1.hi.inet/sites/pipelineReport/index.html
### TODO --> Implementar JOB para borrado de pipelines
### TODO --> Implementar JOB para borrado de ejecuciones de pipelines(esto incluiría el borrado de los rpms asociados)
### TODO --> Añadir sonarQualityControl y gráficas para visualizar la evolución de las métricas de calidad del código (revisar):
http://ci-pipeline/jenkins/view/All/job/CodeQuality-connect/
### TODO --> Controla que versión de tests se lanzan contra cada una de las instalaciones (categorizar los test)
### TODO --> Controlar los fallos del api de jenkins, dependiendo la versión de jenkins, el api, empìeza a devolver NullPointerExceptions
### TODO --> Controlar que la definición del campo enviroments de la deployment table, corresponda con los entornos que se definen a continuación.
### TODO --> Posible error en prePhaseTest en getParameterJob "${INSTALL_JOB_ID}" "N_BUILD" hay que comprobar cuál es el job que realmente ha producido la invocación (revisar).
#### TODO --> Controlar la desinstalación desde jenkins del producto (falta definir la politica de uso de puppet y creeemos que se puede contemplar ahí)
#### TODO --> En el pipeline_plugin añadir en el campo Current installation el link a packagesVersionInstalled.txt (hay que ver como integramos esto con puppet)
#### TODO --> En la deployment table, los campos que no se seleccionen por #, para
              evitar confundirlos con comentarios.
#### TODO --> Hay que revisar la deployment Pipeline para que en los enlaces pongo, siempre y cuando tenga sentido, o upgrade o downgrade. Aunque los enlaces están bine hechos la etiqueta esta mal.
BUGS
====

1 - Instalación del mismo paquete en 2 máquinas del mismo entorno en una pipelina generan un error, en teoría esta probado con Webcalculator hay que ver si es real o hay otro tema que esta generando el problema: http://ci-tdga.hi.inet/jenkins/view/TDGA/job/TDGA-ALL-01-install/1090/consoleFull
2 - Cuando añades la release que tienes que instalar en el 1er entorno falla en el segundo (existe workarround que es quitar la versión en el segundo entorno pero deberíamos trabajar para que funcione correctamente).
