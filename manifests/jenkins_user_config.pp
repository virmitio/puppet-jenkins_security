#
#
define jenkins_security::jenkins_user_config(
  $base_path,
  $extra_properties = {},
  $password = undef,
  $bcrypt_password = undef,
  $fullname = $title,
  $email = undef,
  $api_token = undef,
  $debug = false,
) {

  include augeas

  if $debug {
    notify{"Processing user ${title} -- ${fullname}": }
    notify{"base path - ${title}: ${base_path}": }
  }

  if empty($password) and empty($bcrypt_password) {
    fail("\$password and \$bcrypt_password are both empty for user '${title}'.  At least one of these must be provided.")
  } elsif !empty($password) and !empty($bcrypt_password) {
    warning("\$password and \$bcrypt_password are both provided for user '${title}'.  \$password will be ignored.")
  }

  $realpass = empty($bcrypt_password) ? {
    true  => bcrypt($password),
    false => $bcrypt_password,
  }

  if empty($email) {
#    $email_hash = {}
    $email_str = []
  } else {
#    $email_hash = {
#      'hudson.tasks.Mailer_-UserProperty' => { 
#        plugin => 'mailer@1.8',
#        plugin => 'mailer',
#        emailAddress => [$email],
#      },
#    }
    $email_str = [
#        "set user/properties/hudson.tasks.Mailer_-UserProperty/#attribute/plugin mailer",
        "set user/properties/hudson.tasks.Mailer_-UserProperty/emailAddress/#text '${email}'"
    ]
    augeas{"${base_path}/users/${title}/config.xml#email":
      incl    => "config.xml",
      lens    => "Xml.lns",
      root    => "${base_path}/users/${title}/",
      changes => ["set user/properties/hudson.tasks.Mailer_-UserProperty/#attribute/plugin mailer"],
      onlyif  => "match user/properties/hudson.tasks.Mailer_-UserProperty/#attribute/plugin include '/mailer.?/'",
      require => File["${base_path}/users/${title}"],
      before  => Augeas["${base_path}/users/${title}/config.xml"],
    }
    
  }
  
  if empty($api_token) {
#    $api_hash = {}
    $api_str = []
  } else {
#    $api_hash = {
#      'jenkins.security.ApiTokenProperty' => { 
#        apiToken => [$api_token],
#      },
#    }
    $api_str = ["set user/properties/jenkins.security.ApiTokenProperty/apiToken/#text '${api_token}'"]
  }
  
#  $config_hash = {
#    fullName => [$fullname],
#    properties => merge(merge({
#      'hudson.security.HudsonPrivateSecurityRealm_-Details' => {
#        passwordHash => ["#jbcrypt:${realpass}"],
#      },
#    },
#    $email_hash),$api_hash),
#  }
  $name_str = ["set user/fullName/#text '${fullname}'"]
  $pass_str = ["set user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash/#text '#jbcrypt:${realpass}'"]

#  $opts = {
#    'rootname' => 'user',
#    'xmldeclaration' => "<?xml version='1.0' encoding='UTF-8'?>",
#  }
  
#  $user_config_xml = hash_to_xml($config_hash,$opts)
  $config_str_arr = concat(concat(concat($email_str, $api_str), $name_str), $pass_str)
  
  if !defined(File["${base_path}/users/${title}"]){
    file {"${base_path}/users/${title}":
      ensure  => directory,
      owner   => 'jenkins',
      group   => 'jenkins',
      require => File["${base_path}/users"],
    }
  }
  
#  file {"${base_path}/users/${title}/config.xml":
#    ensure  => file,
#    content => $user_config_xml,
#    owner   => 'jenkins',
#    group   => 'jenkins',
#    require => File["${base_path}/users/${title}"],
#  }

  augeas{"${base_path}/users/${title}/config.xml":
    incl    => "config.xml",
    lens    => "Xml.lns",
    root    => "${base_path}/users/${title}/",
#    lens    => "Xml.aug",
    changes => $config_str_arr,
    require => File["${base_path}/users/${title}"],
  }

}
#  <fullName>zuul service account</fullName>
#  <properties>
#    <hudson.model.PaneStatusProperties>
#      <collapsed/>
#    </hudson.model.PaneStatusProperties>
#    <jenkins.security.ApiTokenProperty>
#      <apiToken>V8RyLnSbR69uvp4v+29mjmByLlt2tHsKyqGhjGhXecf8VfXWmVM5EhUVhgXS+zWa</apiToken>
#    </jenkins.security.ApiTokenProperty>
#    <com.cloudbees.plugins.credentials.UserCredentialsProvider_-UserCredentialsProperty plugin="credentials@1.9.4">
#      <domainCredentialsMap class="hudson.util.CopyOnWriteMap$Hash"/>
#    </com.cloudbees.plugins.credentials.UserCredentialsProvider_-UserCredentialsProperty>
#    <hudson.model.MyViewsProperty>
#      <views>
#        <hudson.model.AllView>
#          <owner class="hudson.model.MyViewsProperty" reference="../../.."/>
#          <name>All</name>
#          <filterExecutors>false</filterExecutors>
#          <filterQueue>false</filterQueue>
#          <properties class="hudson.model.View$PropertyList"/>
#        </hudson.model.AllView>
#      </views>
#    </hudson.model.MyViewsProperty>
#    <hudson.search.UserSearchProperty>
#      <insensitiveSearch>false</insensitiveSearch>
#    </hudson.search.UserSearchProperty>
#    <hudson.security.HudsonPrivateSecurityRealm_-Details>
#      <passwordHash>#jbcrypt:$2a$10$pRzDhZ4RKHQSwEv6tMreKOP6MtAY9N5wrkBToMTv8K7rja201/L3K</passwordHash>
#    </hudson.security.HudsonPrivateSecurityRealm_-Details>
#    <hudson.tasks.Mailer_-UserProperty plugin="mailer@1.8">
#      <emailAddress>zuul@openstack.tld</emailAddress>
#    </hudson.tasks.Mailer_-UserProperty>
#  </properties>
