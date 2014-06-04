define jenkins_security::jenkins_user_config(
  $base_path,
  $extra_properties = {},
  $password = undef,
  $bcrypt_password = undef,
  $fullname = $title,
  $email = undef,
) {

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
    $email_hash = {}
  } else {
    $email_hash = {
      'hudson.tasks.Mailer_-UserProperty plugin="mailer@1.8"' => {
        emailAddress => [$email],
      },
    }
  }
  
  $config_hash = {
    fullName => [$fullname],
    properties => merge({
      'hudson.security.HudsonPrivateSecurityRealm_-Details' => {
        passwordHash => ["#jbcrypt:${realpass}"],
      },
    },
    $email_hash),
  }

  $opts = {
    'rootname' => 'user',
    'xmldeclaration' => "<?xml version='1.0' encoding='UTF-8'?>",
  }
  
  $user_config_xml = hash_to_xml($config_hash,$opts)
  
  if !defined(File["${base_path}"]){
    file {"${base_path}": ensure => directory, }
    owner   => 'jenkins',
    group   => 'jenkins',
  }
  if !defined(File["${base_path}/users"]){
    file {"${base_path}/users": ensure => directory, }
    owner   => 'jenkins',
    group   => 'jenkins',
  }
  if !defined(File["${base_path}/users/${title}"]){
    file {"${base_path}/users/${title}": ensure => directory, }
    owner   => 'jenkins',
    group   => 'jenkins',
  }
  
  file {"${base_path}/users/${title}/config.xml":
    ensure  => file,
    content => $user_config_xml,
    owner   => 'jenkins',
    group   => 'jenkins',
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
