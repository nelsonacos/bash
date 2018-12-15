#!/bin/bash

# Este script crea una copia de seguridad de una base de datos PostgreSQL.

# Dónde colocar las copias de seguridad.
BACKUP_DIR=/var/postgres-backups/$(uname -n)

# Establezca BACKUP_REPORTS en verdadero si está utilizando informes RHEV; de lo contrario, configúrelo en falso.
BACKUP_REPORTS=false

# Cuántos días para retener los archivos de copia de seguridad.
DAYS_TO_RETAIN_BACKUPS=7

# Utilice el formato de fecha de la documentación de RedHat.
BACKUP_DATE=$(date | sed 's/ /_/g' | sed 's/\:/_/g')

# El fichero de copia de seguridad.
CONFIG_BACKUP_FILE="$BACKUP_DIR/config_${BACKUP_DATE}.tar.gz"
REPORTS_CONFIG_BACKUP_FILE="$BACKUP_DIR/reports_config_${BACKUP_DATE}.tar.gz"

# Run as root
[ "$EUID" -eq 0 ] || {
  echo 'Por favor, ejecute con sudo o como root.'
  exit 1
}

# Cree el directorio de copia de seguridad si no existe.
[ -d "$BACKUP_DIR" ] || {
  mkdir -p $BACKUP_DIR
  chmod 775 $BACKUP_DIR
  chgrp wheel $BACKUP_DIR
}

# Copia de seguridad de la base de datos
cd /usr/share/postgres-engine/dbscripts
./backup.sh -s localhost -d engine -u postgres -l $BACKUP_DIR

# Comprimir la copia de seguridad.
gzip $BACKUP_DIR/*.sql

# Copia de seguridad de los archivos de configuración.
CONFIG_FILES="/etc/ovirt-engine/ /etc/sysconfig/ovirt-engine /etc/yum/pluginconf.d/versionlock.list /etc/pki/ovirt-engine/ /usr/share/ovirt-engine/conf/iptables.* /usr/share/ovirt-engine/dbscripts/create_db.sh.log /var/lib/ovirt-engine/backups /var/lib/ovirt-engine/deployments /root/.rnd"

# Crea el fichero tar.
tar czPf $CONFIG_BACKUP_FILE $CONFIG_FILES

if $BACKUP_REPORTS
then
  CONFIG_FILES_FOR_REPORTS="/usr/share/ovirt-engine-reports/reports/users/rhevm-002dadmin.xml /usr/share/ovirt-engine-reports/default_master.properties /usr/share/jasperreports-server-pro/buildomatic"
  tar czPf $REPORTS_CONFIG_BACKUP_FILE $CONFIG_FILES_FOR_REPORTS
fi

# Remover copias de seguridad antiguas
tmpwatch --mtime ${DAYS_TO_RETAIN_BACKUPS}d $BACKUP_DIR

# Esto es como restaurar:
#   cd /usr/share/postgres-engine/dbscripts
#   ./restore.sh -s localhost -u postgres -d engine -f engine_Tue_Mar_19_07_06_42_EDT_2013.sql -r
#
# Details at:
#   https://access.redhat.com/site/solutions/339454

