#! /bin/bash

# Exit immediately upon failure
set -e

if [ "${@}" != "/start.sh" ]
  then
  ARGS="${@}"
fi

if [ ! -f ${BIND_CHROOT_DIR}/etc/rndc.conf ]
  then
  if [ -z "${BIND_RNDC_ALGORITHM}" ] || \
     [ -z "${BIND_RNDC_SECRET}" ]
    then
    echo "No rndc.conf file found and no environment variables are set."
    echo "See README.md for more details."
    echo "-----------------------------------------------------"
    echo "Environment Variables Values:"
    echo "-----------------------------------------------------"
    echo "BIND_RNDC_ALGORITHM: '${BIND_RNDC_ALGORITHM}'"
    echo "BIND_RNDC_SECRET: '${BIND_RNDC_SECRET}'"
    echo
    echo "Generating a new rndc configuration file..."
    rndc-confgen -a -r /dev/urandom -t /var/named/chroot
    BIND_RNDC_ALGORITHM="`cat ${BIND_CHROOT_DIR}/etc/rndc.key | grep algorithm | awk '{print $2}' | cut -f1 -d ';'`"
    BIND_RNDC_SECRET="`cat ${BIND_CHROOT_DIR}/etc/rndc.key | grep secret | cut -f2 -d '"'`"
    echo "-----------------------------------------------------"
    echo "Environment Variables Values:"
    echo "-----------------------------------------------------"
    echo "BIND_RNDC_ALGORITHM: '${BIND_RNDC_ALGORITHM}'"
    echo "BIND_RNDC_SECRET: '${BIND_RNDC_SECRET}'"
    echo
  else
  # Generate a new RNDC configuration file based on supplied variables.
  cat | tee ${BIND_CHROOT_DIR}/etc/rndc.key <<EOF
key "rndc-key" {
        algorithm ${BIND_RNDC_ALGORITHM};
        secret "${BIND_RNDC_SECRET}";
};
EOF
  fi
fi

# include custom bind configuration provided one exists
if [ -f ${BIND_CHROOT_DIR}/custom/named.conf ]
  then
  sed -i 's/^#include "\/custom\/named.conf/include "\/custom\/named.conf/g' ${BIND_CHROOT_DIR}/etc/named.conf
  else
  sed -i 's/^include "\/custom\/named.conf/#include "\/custom\/named.conf/g' ${BIND_CHROOT_DIR}/etc/named.conf
fi

# Re-install named.ca if someone accidently deletes it.
test -f ${BIND_CHROOT_DIR}/master/named.ca || cp -a /var/named/named.ca ${BIND_CHROOT_DIR}/master

# Force ownership and permissions of potentially modified files
find ${BIND_CHROOT_DIR}/etc -type f -exec chmod 640 {} \;
find ${BIND_CHROOT_DIR}/custom -type f -exec chmod 640 {} \;
find ${BIND_CHROOT_DIR}/master -type f -exec chmod 640 {} \;
chown -R root:named ${BIND_CHROOT_DIR}/etc ${BIND_CHROOT_DIR}/custom ${BIND_CHROOT_DIR}/master

# Make sure we're not confused by old, incompletely-shutdown named
# context after restarting the container. Named may not start correctly
# if it thinks it is already running.
rm -rf ${BIND_CHROOT_DIR}/var/run/named/*

if [ -f /var/lib/aide/aide.conf ]
  then
  # override the existing AIDE configuration file if exists
  # in the database directory.
  echo "Found /var/lib/aide/aide.conf. Overriding the default configuration with this."
  ln -sf /var/lib/aide/aide.conf /etc/aide.conf
  chmod 600 /var/lib/aide/aide.conf
fi

if [ ! -f /var/lib/aide/aide.db.gz ]
  then
  echo "Generating a new AIDE database in /var/lib/aide/aide.db.gz..."
  /usr/sbin/aide --init && mv -vf /tmp/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

# Start the DNS server
if [ -n "${ARGS}" ]
  then
  # with command line arguments
  exec /usr/sbin/named -u named -g -t ${BIND_CHROOT_DIR} ${ARGS}
  else
  # without command line arguments
  exec /usr/sbin/named -u named -g -t ${BIND_CHROOT_DIR}
fi
