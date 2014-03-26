#!/bin/bash
# WARNING:
# *** do NOT use TABS for indentation, use SPACES
# *** TABS will cause errors in some linux distributions

# SCRIPT CONFIGURATION:
script_name=asctl
intel_conf_dir=/etc/intel/cloudsecurity
package_name=attestation-service
package_dir=/opt/intel/cloudsecurity/${package_name}
package_config_filename=${intel_conf_dir}/${package_name}.properties
package_env_filename=${package_dir}/${package_name}.env
package_install_filename=${package_dir}/${package_name}.install
#mysql_required_version=5.0
#mysql_setup_log=/var/log/intel.${package_name}.install.log
#mysql_script_dir=${package_dir}/database
#glassfish_required_version=4.0
webservice_application_name=mtwilson
#webservice_application_name=AttestationService
#java_required_version=1.7.0_51

# FUNCTION LIBRARY, VERSION INFORMATION, and LOCAL CONFIGURATION
if [ -f "${package_dir}/functions" ]; then . "${package_dir}/functions"; else echo "Missing file: ${package_dir}/functions"; exit 1; fi
if [ -f "${package_dir}/version" ]; then . "${package_dir}/version"; else echo_warning "Missing file: ${package_dir}/version"; fi
shell_include_files "${package_env_filename}" "${package_install_filename}"
load_conf 2>&1 >/dev/null
load_defaults 2>&1 >/dev/null
#if [ -f /root/mtwilson.env ]; then  . /root/mtwilson.env; fi

# bug #509 the sql script setup is moved to a java program, this function is not needed anymore
#list_mysql_install_scripts() {
#    echo ${mysql_script_dir}/20120327214603_create_changelog.sql
#    echo ${mysql_script_dir}/20120328172740_create_0_5_1_schema.sql
##    echo ${mysql_script_dir}/20120403185252_add_procedure_Insert_GKV_Record.sql
##    echo 20120405021354_add_procedure_authenticate_user.sql
#    echo ${mysql_script_dir}/20120328173612_ta_db-0.5.1-data.sql
##    echo ${mysql_script_dir}/20120405161725_add_procedure_getuserfirstlastnames.sql
#    echo ${mysql_script_dir}/201207101_saml_cache_patch-ta_db-0.5-to-0.5.2.sql
#    echo ${mysql_script_dir}/20120829_audit_log.sql
#    echo ${mysql_script_dir}/20120831_patch_rc2.sql
#    echo ${mysql_script_dir}/20120920085200_patch_rc3.sql
#}


## bug #509 the sql script setup is moved to a java program, this function is not needed anymore
#list_mysql_upgrade_scripts() {
#    echo ${mysql_script_dir}/20120327214603_create_changelog.sql
#    echo ${mysql_script_dir}/20120328172740_create_0_5_1_schema.sql
#    echo ${mysql_script_dir}/20120328172802_patch-ta_db-0.5-to-0.5.1.sql
#    echo ${mysql_script_dir}/20120403185252_add_procedure_Insert_GKV_Record.sql
#    echo ${mysql_script_dir}/201207101_saml_cache_patch-ta_db-0.5-to-0.5.2.sql
#    echo ${mysql_script_dir}/20120829_audit_log.sql
#    echo ${mysql_script_dir}/20120831_patch_rc2.sql
#}


# This function downloads the Privacy CA's AIK Certificate and EK Certificate.
# TODO XXX this should probably be ported to the Attestation Service Java code
# so it will work on any platform...
# Environment:
#   - if the configuration file includes "privacyca.server" then this address
#     will be used. otherwise, the user will be prompted for this value and it
#     will be saved into the configuration file.
# Parameters: None
# Input: Privacy CA Server and Password
# Output: PrivacyCA.cer and Endorsement.cer are saved into the config dir
download_privacyca_certs() {
  local privacyca_server_config
  if [ -z "${PRIVACYCA_SERVER}" ]; then
    #privacyca_server_config=`read_property_from_file privacyca.server "${package_config_filename}"`
    #PRIVACYCA_SERVER=${privacyca_server_config}
    prompt_with_default PRIVACYCA_SERVER "Privacy CA Server:"
  fi

  if [ -n "${PRIVACYCA_SERVER}" ]; then
    # check if the privacy ca password is saved in a properties file
    #local default_privacyca_username=${PRIVACYCA_DOWNLOAD_USERNAME:-`read_property_from_file ClientFilesDownloadUsername ${intel_conf_dir}/PrivacyCA.properties`}
    echo "Login to download the Privacy CA client files"
    if [ -z "${PRIVACYCA_DOWNLOAD_USERNAME}" ]; then
      prompt_with_default PRIVACYCA_DOWNLOAD_USERNAME "Username:" ${PRIVACYCA_DOWNLOAD_USERNAME}
      export PRIVACYCA_DOWNLOAD_USERNAME="$PRIVACYCA_DOWNLOAD_USERNAME"
    fi
    if [ -z "${PRIVACYCA_DOWNLOAD_PASSWORD}" ]; then
      prompt_with_default_password PRIVACYCA_DOWNLOAD_PASSWORD "Password:" ${default_privacyca_password}
      export PRIVACYCA_DOWNLOAD_PASSWORD="$PRIVACYCA_DOWNLOAD_PASSWORD"
    fi
    
    echo "Connecting to Privacy CA..."

    # zip file downloaded to /tmp so that if client and server are same machine, the download won't clobber the server's copy of clientfiles.zip in /etc
    local zipfile=/tmp/clientfiles.zip
    touch $zipfile
    chmod 600 $zipfile
    # XXX password in URL is insecure in systems that have user accounts or software which should not know this password
    #wget --no-proxy --no-check-certificate -q "https://${PRIVACYCA_SERVER}:$DEFAULT_API_PORT/HisPrivacyCAWebServices2/clientfiles.zip?user=${PRIVACYCA_DOWNLOAD_USERNAME}&password=${PRIVACYCA_DOWNLOAD_PASSWORD}" -O ${zipfile}
	encodedPW=$(echo "${PRIVACYCA_DOWNLOAD_PASSWORD}" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/!/%21/g' -e 's/"/%22/g' -e 's/#/%23/g' -e 's/\$/%24/g' -e 's/\&/%26/g' -e 's/'\''/%27/g' -e 's/(/%28/g' -e 's/)/%29/g' -e 's/\*/%2a/g' -e 's/+/%2b/g' -e 's/,/%2c/g' -e 's/-/%2d/g' -e 's/\./%2e/g' -e 's/\//%2f/g' -e 's/:/%3a/g' -e 's/;/%3b/g' -e 's//%3e/g' -e 's/?/%3f/g' -e 's/@/%40/g' -e 's/\[/%5b/g' -e 's/\\/%5c/g' -e 's/\]/%5d/g' -e 's/\^/%5e/g' -e 's/_/%5f/g' -e 's/`/%60/g' -e 's/{/%7b/g' -e 's/|/%7c/g' -e 's/}/%7d/g' -e 's/~/%7e/g')
	tomcat_detect > /dev/null 2>&1;glassfish_detect > /dev/null 2>&1;
    if [ -z "$DEFAULT_API_PORT" ]; then
      if using_tomcat; then
        DEFAULT_API_PORT=8443
      else
        DEFAULT_API_PORT=8181
      fi
    fi
    wget --no-proxy --no-check-certificate -q "https://${PRIVACYCA_SERVER}:$DEFAULT_API_PORT/HisPrivacyCAWebServices2/clientfiles.zip?user=${PRIVACYCA_DOWNLOAD_USERNAME}&password=${encodedPW}" -O ${zipfile}
    if [ -s ${zipfile} ]; then
      mkdir -p /tmp/clientfiles.x
      chmod -R 600 /tmp/clientfiles.x
      unzip -o ${zipfile} -d /tmp/clientfiles.x
      rm -f ${zipfile}

      if using_glassfish; then
        glassfish_permissions /tmp/clientfiles.x
      else
        tomcat_permissions /tmp/clientfiles.x
      fi

      mv /tmp/clientfiles.x/hisprovisioner.properties ${intel_conf_dir}/hisprovisioner.properties
      mv /tmp/clientfiles.x/PrivacyCA.cer ${intel_conf_dir}/PrivacyCA.cer
      mv /tmp/clientfiles.x/endorsement.p12 ${intel_conf_dir}/endorsement.p12
      rm -r /tmp/clientfiles.x

      # create the PrivacyCA.pem cert so it can be download from the portal
      if [ -f "$intel_conf_dir/PrivacyCA.cer" ]; then
        openssl x509 -inform der -in "$intel_conf_dir/PrivacyCA.cer" -out "$intel_conf_dir/PrivacyCA.pem"
      else
        echo_warning "Missing PrivacyCA.cer.  File will not be available via portals"
      fi

      # create the list of trusted privacy ca's if it doesn't exist.  the list is in PrivacyCA.p12.pem
      if [ ! -f "${intel_conf_dir}/PrivacyCA.p12.pem" ]; then
          touch "${intel_conf_dir}/PrivacyCA.p12.pem"
          chmod 600 "${intel_conf_dir}/PrivacyCA.p12.pem"
      fi
      # add the privacy ca certificate to a list of trusted privacy ca's
      openssl x509 -in "${intel_conf_dir}/PrivacyCA.cer" -inform der -outform pem >> "${intel_conf_dir}/PrivacyCA.p12.pem"
      # if we got here with user input then save the Privacy CA server name in properties file
      if [ -z "${privacyca_server_config}" ]; then
        update_property_in_file privacyca.server "${package_config_filename}" "${PRIVACYCA_SERVER}"
      fi
      # use the password in hisprovisioner.propeties to extract the Endorsement certificate from endorsement.p12, then delete the password
      if [ -f "${intel_conf_dir}/endorsement.p12" ]; then
        export endorsement_password="$ENDORSEMENT_P12_PASS"   #`read_property_from_file EndorsementP12Pass ${intel_conf_dir}/hisprovisioner.properties`
        openssl pkcs12 -in ${intel_conf_dir}/endorsement.p12 -out ${intel_conf_dir}/privacyca-endorsement.pem -nokeys -passin env:endorsement_password
        export endorsement_password=
        rm ${intel_conf_dir}/hisprovisioner.properties
        rm ${intel_conf_dir}/endorsement.p12
        openssl x509 -inform pem -in ${intel_conf_dir}/privacyca-endorsement.pem -out ${intel_conf_dir}/privacyca-endorsement.crt -outform der
        chmod 600 ${intel_conf_dir}/privacyca-endorsement.crt
        #glassfish_permissions ${intel_conf_dir}/privacyca-endorsement.crt
        rm ${intel_conf_dir}/privacyca-endorsement.pem
      else
        echo_failure "Cannot unzip package from Privacy CA"
      fi
    else
      echo_failure "Cannot connect to Privacy CA: ${PRIVACYCA_SERVER}"
    fi
  else
    echo_failure "PrivacyCA Server and Password are required in order to download certificates"
  fi
  
}


create_saml_key() {
  if no_java ${java_required_version:-1.7}; then echo "Cannot find Java ${java_required_version:-1.7} or later"; exit 1; fi
  # TODO:  keystore password can be set in environment variable and passed like env:varname (see docs.. only in java 1.7 did they copy this from openssl)... same for key password
  # windows path: C:\Intel\CloudSecurity\SAML.jks
  # the saml.keystore.file property is just a file name and not an absolute path
  # TODO XXX: use convention over configuration... document that the SAML keystore file is a file called SAML.jks inside the
  # configuration directory, and use that fact everywhere instead of reading a configuration.
  saml_keystore_file="${SAML_KEYSTORE_FILE:-SAML.jks}"          #`read_property_from_file saml.keystore.file ${package_config_filename}`
  saml_keystore_password="$SAML_KEYSTORE_PASSWORD"  #`read_property_from_file saml.keystore.password ${package_config_filename}`
  saml_key_alias="$SAML_KEY_ALIAS"                  #`read_property_from_file saml.key.alias ${package_config_filename}`
  saml_key_password="$SAML_KEY_PASSWORD"            #`read_property_from_file saml.key.password ${package_config_filename}`
  # prepend the configuration directory to the keystore filename
  if [ ! -f $saml_keystore_file ]; then
    saml_keystore_file=${intel_conf_dir}/${saml_keystore_file}
  fi
  
  saml_keystore_password=${saml_keystore_password:-"changeit"}
  saml_key_alias=${saml_key_alias:-"samlkey1"}
  saml_key_password=${saml_key_password:-"changeit"}
  keytool=${JAVA_HOME}/bin/keytool
  samlkey_exists=`$keytool -list -keystore ${saml_keystore_file} -storepass ${saml_keystore_password} | grep PrivateKeyEntry | grep "^${saml_key_alias}"`
  if [ -n "${samlkey_exists}" ]; then
    echo "SAML key with alias ${saml_key_alias} already exists in ${saml_keystore_file}"
    # TODO: check if the key is at least 2048 bits. if not, prompt to create a new key.
  else
    $keytool -genkey -alias ${saml_key_alias} -keyalg RSA  -keysize 2048 -keystore ${saml_keystore_file} -storepass ${saml_keystore_password} -dname "CN=mtwilson, OU=Mt Wilson, O=Intel, L=Folsom, ST=CA, C=US" -validity 3650  -keypass ${saml_key_password}
  fi
  chmod 600 ${saml_keystore_file}
  # export the SAML certificate so it can be easily provided to API clients
  $keytool -export -alias ${saml_key_alias} -keystore ${saml_keystore_file}  -storepass ${saml_keystore_password} -file ${intel_conf_dir}/saml.crt
  openssl x509 -in ${intel_conf_dir}/saml.crt -inform der -out ${intel_conf_dir}/saml.crt.pem -outform pem
  chmod 600 ${intel_conf_dir}/saml.crt ${intel_conf_dir}/saml.crt.pem

  #saml.issuer=https://localhost:8181
  local saml_issuer=""
  if using_glassfish; then
    saml_issuer="https://${MTWILSON_SERVER:-127.0.0.1}:8181"
  else
    saml_issuer="https://${MTWILSON_SERVER:-127.0.0.1}:8443"
    #saml_issuer=`echo $saml_issuer |  sed -e 's/\\//g'`
  fi
  update_property_in_file saml.issuer "${package_config_filename}" "${saml_issuer}"
}

create_data_encryption_key() {
#  # first check to see if there is a key already set
#  data_encryption_key=`read_property_from_file mtwilson.as.dek ${package_config_filename}`
#  if [[ -n "${data_encryption_key}" ]]; then
#    echo "Data encryption key already exists"
#  else
#    echo "Creating data encryption key"
    mtwilson setup EncryptDatabase
#  fi
}


setup_interactive_install() {
  if using_mysql; then   
    if [ -n "$mysql" ]; then
      mysql_configure_connection "${package_config_filename}" mountwilson.as.db
      mysql_configure_connection "${intel_conf_dir}/audit-handler.properties" mountwilson.audit.db
      mysql_create_database
      mtwilson setup InitDatabase mysql
    fi
  elif using_postgres; then
    if [ -n "$psql" ]; then
      echo "inside psql: $psql"
      postgres_configure_connection "${package_config_filename}" mountwilson.as.db
      postgres_configure_connection "${intel_conf_dir}/audit-handler.properties" mountwilson.audit.db
      postgres_create_database
      mtwilson setup InitDatabase postgresql
    else
      echo "psql not defined"
      exit 1
    fi
  fi
  create_saml_key 
  download_privacyca_certs
  create_data_encryption_key
  if [ -n "$GLASSFISH_HOME" ]; then
    glassfish_running
    if [ -z "$GLASSFISH_RUNNING" ]; then
      glassfish_start_report
    fi
  elif [ -n "$TOMCAT_HOME" ]; then
    tomcat_running
    if [ -z "$TOMCAT_RUNNING" ]; then
      tomcat_start_report
    fi
  fi
  
  if [ -n "$MTWILSON_SETUP_NODEPLOY" ]; then
    webservice_start_report "${webservice_application_name}"
  else
    webservice_uninstall "${webservice_application_name}"
    webservice_install "${webservice_application_name}" "${package_dir}"/mtwilson.war
    #if using_glassfish; then
    #  sleep 60s
    #  glassfish_restart
    #elif using_tomcat; then
    #  tomcat_restart
    #fi
      echo -n "Waiting for ${webservice_application_name} to become accessible... "
      sleep 50s        #XXX TODO: remove when we have solution for webserver up
      echo "Done"
      webservice_running_report "${webservice_application_name}"
  fi
}

setup() {
#  mysql_clear; java_clear; glassfish_clear;
  mtwilson setup-env > "${package_env_filename}"
  . "${package_env_filename}"
#  if [[ -z "$JAVA_HOME" || -z "$GLASSFISH_HOME" || -z "$mysql" ]]; then
#      echo_warning "Missing one or more required packages"
#      print_env_summary_report
#      exit 1
#  fi
  setup_interactive_install
}



RETVAL=0




# See how we were called.
case "$1" in
  version)
        echo "${package_name}"
  echo "Version ${VERSION:-Unknown}"
  echo "Build ${BUILD:-Unknown}"
        ;;
  start)
        webservice_start_report "${webservice_application_name}"
        ;;
  stop)
        webservice_stop_report "${webservice_application_name}"
        ;;
  status)
      #if using_glassfish; then  
      #  glassfish_running_report
      #elif using_tomcat; then
      #  tomcat_running_report
      #fi
        webservice_running_report "${webservice_application_name}"
        ;;
  restart)
        webservice_stop_report "${webservice_application_name}"
        sleep 2
        webservice_start_report "${webservice_application_name}"
        ;;
  glassfish-restart)
        glassfish_restart
        ;;
  glassfish-stop)
        glassfish_shutdown
        ;;
  setup)
        setup
        ;;
  setup-env)
  # for sysadmin convenience
        mtwilson setup-env
        ;;
  setup-env-write)
  # for sysadmin convenience
        mtwilson setup-env > "${package_env_filename}"
        ;;
  edit)
        update_property_in_file "${2}" "${package_config_filename}" "${3}"
        ;;
  show)
        read_property_from_file "${2}" "${package_config_filename}"
        ;;
  uninstall)
        datestr=`date +%Y-%m-%d.%H%M`
        webservice_uninstall "${webservice_application_name}"
        if [ -f "${package_config_filename}" ]; then
          mkdir -p "${intel_conf_dir}"
          cp "${package_config_filename}" "${intel_conf_dir}"/${package_name}.properties.${datestr}
          echo "Saved configuration file in ${intel_conf_dir}/${package_name}.properties.${datestr}"
        fi
        # prevent disaster by ensuring that package_dir is inside /opt/intel
        if [[ "${package_dir}" == /opt/intel/* ]]; then
          rm -rf "${package_dir}"
        fi
  rm /usr/local/bin/${script_name}
        ;;
  saml-createkey)
        create_saml_key
        ;;
  privacyca-setup)
        download_privacyca_certs
        ;;
  help)
        echo "Usage: ${script_name} {setup|start|stop|status|uninstall|saml-createkey|privacyca-setup}"
        ;;
  *)
        echo "Usage: ${script_name} {setup|start|stop|status|uninstall|saml-createkey|privacyca-setup}"
        exit 1
esac

exit $RETVAL