{%
   include-markdown '../../deps/snitch_cluster/docs/ug/getting_started.md'
   start="<!--start-section-1-->"
   end="<!--end-section-1-->"
%}

{%
   include-markdown '../../util/container/README.md'
   start='<!--start-docs-->'
%}

{%
   include-markdown '../../deps/snitch_cluster/docs/ug/getting_started.md'
   start="<!--start-section-2-->"
   end="<!--end-section-2-->"
%}

You will also have to install the GCC compiler toolchain for CVA6 and `verible`. You can use the commands in the `before_script` section of the [Gitlab CI file](https://github.com/pulp-platform/occamy/blob/{{ branch }}/.gitlab-ci.yml).