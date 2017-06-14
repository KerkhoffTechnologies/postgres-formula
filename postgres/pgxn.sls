{% from "postgres/map.jinja" import postgres with context %}

{% if postgres.use_upstream_repo %}
include:
  - postgres.upstream
{% endif %}

install-pgxn-client:
  pkg.installed:
    - name: {{ postgres.pkg_pgxn }}
    - name: make
    - name: gcc
    - refresh: {{ postgres.use_upstream_repo }}

{% for name, db in postgres.databases.items()  %}
{% if db.pgxn is defined %}
{% for list_entry in db.pgxn %}

{% set ext = '' %}
{% set ext_opts = {} %}

{% if list_entry is not string %}
{% set ext = list_entry.items()[0][0] %}
{% set ext_opts = list_entry.items()[0][1] %}
{% else %}
{% set ext = list_entry %}
{% endif %}

postgres-pgxn-install-ext-{{ ext }}:
  cmd.run:
    - require:
      - pkg: install-pgxn-client
    - onlyif: which pgxn
{% if not ext_opts['update'] %}
    - creates: /usr/lib/postgresql/{{ postgres.version }}/lib/{{ ext }}.so
{% endif %} 
{% if ext_opts['ver'] is defined %}
    - name: pgxn install {{ ext }}={{ ext_opts['ver'] }}
{% else %}
    - name: pgxn install {{ ext }}
{% endif %} 

postgres-pgxn-ext-{{ ext }}-for-db-{{ name }}:
  postgres_extension.present:
    - name: {{ ext }}
    - user: {{ db.get('runas', 'postgres') }}
    - maintenance_db: {{ name }}
{% endfor %}
{% endif %}

{% endfor%}
