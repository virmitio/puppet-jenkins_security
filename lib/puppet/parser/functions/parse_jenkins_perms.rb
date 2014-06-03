Puppet::Parser::Functions.newfunction(:parse_jenkins_perms, :type => :rvalue, :doc =>
  "Function that converts a hash of Jenkins users and permission to a string array for insertion into a config XML") do |args|
  if args.length != 1
    raise Puppet::Error, "#parse_jenkins_perms accepts only one (1) argument, you passed #{args.length}"
  end

  args.each do |arg|
    if arg.class != Hash
      raise Puppet::Error, "#parse_jenkins_perms requires a hash for argument, you passed a #{arg.class}"
    end
  end

  perm_arr = Array.new
  
  args[0].each{ |user, all_perms|
    all_perms.each{ |perm_class, perms|
      perms.each{ |perm|
        case perm_class
          when 'overall'
            perm_arr.push("hudson.model.Hudson.#{perm}:#{user}")
          when 'slave'
            perm_arr.push("hudson.model.Computer.#{perm}:#{user}")
          when 'job'
            perm_arr.push("hudson.model.Item.#{perm}:#{user}")
          when 'run'
            perm_arr.push("hudson.model.Run.#{perm}:#{user}")
          when 'view'
            perm_arr.push("hudson.model.View.#{perm}:#{user}")
          else
            perm_arr.push("#{perm_class}.#{perm}:#{user}")
        end
      }
    }
  }
  
  return perm_arr

end
