#
#
# Parameters:
#   [security_realm]
#   'none'    -  (default) This realm means that no attempt at authentication will take place, and user login and actions cannot be tracked.  This realm only functions properly when [permission_type] is 'open'.
#   'servlet' -  Legacy.  Use the servlet container to authenticate users.
#   'jenkins' -  Use internal Jenkins database for user authentication.
#   'ldap'    -  Use an external LDAP host for user authentication.
#   'unix'    -  Use the underlying *nix system for user authentication.
#                  NOTE: When selecting 'unix', either Jenkins needs to run as 'root' or User 'jenkins' needs to belong to group 'root' and `chmod g+r /etc/shadow` must be done to enable Jenkins to read /etc/shadow.
#
#   [realm_options]
#   Hash containing key-value variable settings which are [security_realm]-specific.  Known variables for each realm are listed below.  Behaviour for use of unlisted variables is undefined.
#   'none'   : N/A
#   'servlet': N/A
#   'jenkins':
#       'disableSignup' - boolean (default: false)
#       'enableCaptcha' - boolean (default: false)
#   'ldap'   :
#       'server' - string, 'server_name:port'
#       'rootDN' - string, 'domain_name'
#       'inhibitInferRootDN' - boolean (default: false)
#       'userSearchBase' - string
#       'userSearch' - string (eg. 'uid={0}')
#       'disableMailAddressResolver' - boolean (default: false)
#   'unix'   :
#        'serviceName' - string, (eg. 'sshd')
#
#   [permission_type]
#   Method used for assigning permissions to users.
#   'open'         : All users have full control without needing to log in.
#   'legacy'       : Users with the "admin" role have full control.  All other users (including Anonymous) are read-only.
#   'binary'       : Logged in users have full control.  Anonymous users have read-only access.
#   'matrix'       : Assign specific global permissions to specific users.  Permissions must be explicitly granted.
#   'projectmatrix': Assign specific permissions to specific users at either global or project level.  Global permission grants override a lack of project permission grants.  Permissions must be explicitly granted.
#
#   [permissions]
#   Array of Jenkins permission lines.  Format for each string in the array:
#           'perm_path:user'
#       eg. 'hudson.model.Computer.Build:anonymous'
#

class jenkins_security::global_config (
  $security_realm = 'none',
  $realm_options = {},
  $permission_type = 'open',
  $permissions = {},
  $base_path = $::osfamily ? {
                 RedHat  => '/var/lib/jenkins',
                 Suse    => '/var/lib/jenkins',
                 Debian  => '/var/lib/jenkins',
                 Windows => "C:/ProgramData/jenkins",
                 default => '/var/lib/jenkins'
               },
  $custom_config = {},
  $executors = 2,
) {

  # realm string
  $realm_class = $security_realm ? {
    'none'    => 'hudson.security.SecurityRealm$None',
    'servlet' => 'hudson.security.LegacySecurityRealm',
    'jenkins' => 'hudson.security.HudsonPrivateSecurityRealm',
    'ldap'    => 'hudson.security.LDAPSecurityRealm" plugin="ldap',
    'unix'    => 'hudson.security.PAMSecurityRealm" plugin="pam-auth',
    default   => ''
  }
  if $realm_class == '' {
    fail("Jenkins security realm '${security_realm}' is not valid.")
  }

  # permissions/auth type string
  $auth_class = $permission_type ? {
    'open'          => 'hudson.security.AuthorizationStrategy$Unsecured',
    'legacy'        => 'hudson.security.LegacyAuthorizationStrategy',
    'binary'        => 'hudson.security.FullControlOnceLoggedInAuthorizationStrategy',
    'matrix'        => 'hudson.security.GlobalMatrixAuthorizationStrategy',
    'projectmatrix' => 'hudson.security.ProjectMatrixAuthorizationStrategy',
    default         => ''
  }
  if $auth_class == '' {
    fail("Jenkins authorization strategy / permission type '${permission_type}' is not valid.")
  }

#  $config_hash = merge({
##    'version' => [1.562],
#    'numExecutors' => [$executors],
#    'mode' => ['NORMAL'],
#    'useSecurity' => [true],
#    'securityRealm' => merge({
#      'class' => $realm_class,
#    },$realm_options),
#    'authorizationStrategy' => {
#      'class' => $auth_class,
#      'permission' => parse_jenkins_perms($permissions),
#    },
#    'disableRememberMe' => [false],
#    'projectNamingStrategy'  => {
#      'class' => 'jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy',
#    },
#    'workspaceDir' =>['${JENKINS_HOME}/workspace/${ITEM_FULLNAME}'],
#    'buildsDir' => ['${ITEM_ROOTDIR}/builds</buildsDir'],
#    'viewsTabBar' => {
#      'class' => 'hudson.views.DefaultViewsTabBar',
#    },
#    'myViewsTabBar' => {
#      'class' => 'hudson.views.DefaultMyViewsTabBar',
#    },
##    'clouds' => {},
#    'quietPeriod' => [5],
#    'scmCheckoutRetryCount' => [0],
#    'views' => {
#      'hudson.model.AllView' => {
#        'owner' => {
#          'class' => 'hudson',
#          'reference' => '../../..',
#        },
#        'name' => ['All'],
#        'filterExecutors' => [false],
#        'filterQueue' => [false],
#        'properties' => {
#          'class' => 'hudson.model.View$PropertyList',
#        },
#      },
#    },
#    'primaryView' => ['All'],
#    'slaveAgentPort' => [0],
#    'label' => [''],
#  }, $custom_config)
#
#  $opts = {
#    'rootname' => 'hudson',
#    'xmldeclaration' => "<?xml version='1.0' encoding='UTF-8'?>",
#  }

  $realm_opts_str = prefix(suffix(join_keys_to_values($realm_options, "/#text '"), "'"),"set hudson/securityRealm/")
#  $auth_perms_str = prefix(suffix(join_keys_to_values($realm_class, ":"), "'"),"set hudson/authorizationStrategy/permission[#attribute]/#text '")
  $parsed_perms = parse_jenkins_perms($permissions)
  $auth_perms_str = prefix(
                      suffix(
                        join_keys_to_values(
                          hash( zip($parsed_perms, $parsed_perms)),
                        "']/#text '"),
                      "'"),
                    "set hudson/authorizationStrategy/permission[#text='")
#  $config_arr = concat(concat([
  $config_arr = [
    "set hudson/numExecutors/#text ${executors}",
    "set hudson/mode/#text NORMAL",
    "set hudson/useSecurity/#text true",
    "set hudson/disableRememberMe/#text false",
    'set hudson/workspaceDir/#text "${JENKINS_HOME}/workspace/${ITEM_FULLNAME}"',
    'set hudson/buildsDir/#text "${ITEM_ROOTDIR}/builds/buildsDir"',
    "set hudson/quietPeriod/#text 5",
    "set hudson/scmCheckoutRetryCount/#text 0",
    "set hudson/primaryView/#text All",
    "set hudson/slaveAgentPort/#text 0",
    "set hudson/label/#text ''",
#  ]
#  $config_arr_base2 = [
    "set hudson/securityRealm/#attribute/class '${realm_class}'",
    "set hudson/authorizationStrategy/#attribute/class '${auth_class}'",
    "set hudson/projectNamingStrategy/#attribute/class 'jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy'",
    "set hudson/viewsTabBar/#attribute/class 'hudson.views.DefaultViewsTabBar'",
    "set hudson/myViewsTabBar/#attribute/class 'hudson.views.DefaultMyViewsTabBar'",
    "set hudson/views/hudson.model.AllView/name/#text 'All'",
    "set hudson/views/hudson.model.AllView/filterExecutors/#text false",
    "set hudson/views/hudson.model.AllView/filterQueue/#text false",
    "set hudson/views/hudson.model.AllView/properties/#attribute/class 'hudson.model.View$PropertyList'",
    "set hudson/views/hudson.model.AllView/owner/#attribute/class 'hudson'",
    "set hudson/views/hudson.model.AllView/owner/#attribute/reference '../../..'"
  ] #, $realm_opts_str), $auth_perms_str)

#  $global_config_xml = hash_to_xml($config_hash,$opts)

#  file {"${base_path}/config.xml":
#    ensure  => file,
#    content => $global_config_xml,
#    owner   => 'jenkins',
#    group   => 'jenkins',
#  }

#  file {"${base_path}/config.test":
#    ensure  => file,
#    content => join($config_arr, "\n"),
#    owner   => 'jenkins',
#    group   => 'jenkins',
#  }


#  augeas{"${base_path}/config.xml":
#    incl    => "${base_path}/config.xml",
#    lens    => "Xml.lns",
#    changes => $config_arr,
#    require => File["${base_path}/config.xml"],
#  }

  include augeas

  augeas{"${base_path}/config.xml":
#    incl    => "${base_path}/config.xml",
    incl    => "config.xml",
    lens    => "Xml.lns",
    root    => "${base_path}",
    changes => $config_arr,
#    changes => $config_arr_base2,
#    changes => [
#        "set hudson/numExecutors/#text ${executors}",
#        "set hudson/mode/#text NORMAL"
#      ],
#    require => File["${base_path}/config.xml"],
#    require => Augeas["${base_path}/config.xml"],
  }

  augeas{"${base_path}/config.xml#realm":
    incl    => "config.xml",
    lens    => "Xml.lns",
    root    => "${base_path}",
    changes => $realm_opts_str,
    require => Augeas["${base_path}/config.xml"],
  }

  augeas{"${base_path}/config.xml#perms":
    incl    => "config.xml",
    lens    => "Xml.lns",
    root    => "${base_path}",
    changes => $auth_perms_str,
    require => Augeas["${base_path}/config.xml"],
  }



}
