
class {'jenkins': }
class {'jenkins_security':
  require   => Class['jenkins'],
}

