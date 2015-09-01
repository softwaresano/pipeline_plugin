GIT HOOKS
=========

Se utilizan hooks de git para que cada vez que se haga un **git commit**  al repositorio:

* Se compruebe que el nombre de las ramas siga las [reglas de nombrado](https://colabora.pdi.inet/kbportal/PLCwiki/Guidelines/Common/Software%20Configuration%20Management/SCM-Branch%20Structures.aspx). Ej: feature/PTWOPCDN-10127_add_hook_for_puppet_validation
* Cada commit se asocie a una tarea de jira, y así poder visualizar en jira todos los commits asociados a una tarea.
* Se compruebe que los ficheros de los que se hace commit son correctos sintácticamente 
 (actualmente sólo está implementado para puppet, bash, sh, python,yaml,json y rpm specfiles)

Instalación
-----------

Ejecuta install.sh

```
./install.sh
```

Crear prefijo de jira
---------------------

Los nombres de los repositorios en github siguen la nomenclatura <project>-<component>. (Ejemplo cdn: cdn-deploy)
y cada proyecto tiene asociado un prefijo de JIRA. Una issue en JIRA es del estilo <prefix_jira>-<id_jira>.(Ejemplo cdn: PTWOPCDN-10127).

Para poder asociar los commits a las tareas de jira se ha de añadir crear el fichero:

```
mkdir -p ~/.git_templates/hooks/projects_id/cdn/
echo PTWOPCDN >~/.git_templates/hooks/projects_id/cdn/jira_prefix
```

Deshabilitar prefijo de jira
----------------------------

Por ejemplo para el proyecto myp

```
mkdir -p ~/.git_templates/hooks/projects_id/myp/
echo "WITHOUT_JIRA" >~/.git_templates/hooks/projects_id/myp/jira_prefix
```


Si no se quisiera asociar el prefijo de jira al proyecto. 




Actualización de hooks en los repositorios
------------------------------------------

Por defecto, si se había clonado un repo antes de configurar los hooks, en el home del
repositorio de git se debe ejecutar:

```
git init
```

con esto se añadirán los hooks



