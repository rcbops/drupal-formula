{% from "drupal/db.jinja" import drupal with context %}

# Include standard mysql config
include:
  - mysql

# Set up the database user drupal will use
drupal_db_user:

  mysql_database.present:
    - name: {{ drupal.db_name }}
    - connection_default_file: /root/.my.cnf

  # Create the user
  mysql_user.present:
    - name:     {{ drupal.db_user }}
    - password: {{ drupal.db_password }}
    - host:     {{ drupal.db_host }}
    - connection_default_file: /root/.my.cnf

  # Assign permissions
  mysql_grants.present:
    - user:     {{ drupal.db_user }}
    - host:     {{ drupal.db_host }}
    - database: '{{ drupal.db_name }}.*'
    - grant: select, insert, update, delete, create, drop, index, alter, lock tables, create temporary tables
    - connection_default_file: /root/.my.cnf
