require "sqlite3"

class PowerDNSSQLite

  def db
    @db ||= SQLite3::Database.new "powerdns.db"
  end

  def create_domain( domain )

    nameserver = "ns.#{domain}"
    email = "dnsadmin.#{domain}"
    serial = Time.now.strftime( "%Y%m%d%H%M%S" )
    ttl = 3600

    begin
      db.execute "insert into domains " +
        "(name, type) values ('#{domain}', 'NATIVE')"
      
      # Start of authority (SOA) record
      db.execute "insert into records " +
        "(domain_id, name, type, content, ttl, prio) " +
        "select id, '#{domain}', 'SOA', " +
        "'#{nameserver} #{email} #{serial} 3600 600 86400', #{ttl}, 0 " +
        "from domains where name='#{domain}'"

      # Name server record
      db.execute "insert into records " +
        "(domain_id, name, type, content, ttl, prio) " +
        "select id, '#{domain}', 'NS', '#{nameserver}', #{ttl}, 0 " +
        "from domains where name='#{domain}'"
    rescue SQLite3::ConstraintException
      "Domain already exists."
    end

    "Domain created."
  end

  def delete_domain( domain )
    db.execute "delete from records where name = '#{domain}'"
    db.execute "delete from domains where name = '#{domain}'"
    "Domain deleted."
  end

  def list_name_servers( domain )
    db.execute( "select content from records " +
                "where type = 'NS' and " +
                "name = '#{domain}'" ).flatten
  end

  def create_record( params )
    name = record_name( params )
    type = params[:record_type]
    content = params[:content]
    ttl = params[:ttl]
    prio = params[:prio] ||= 0

    db.execute "insert into records " +
      "(domain_id, name, type, content, ttl, prio) " +
      "select id, '#{name}', '#{type}', '#{content}', #{ttl}, #{prio} " +
      "from domains where name = '#{params[:domain]}'"

    "Record created."
  end

  def update_record( params )
    name = record_name( params )
    type = params[:record_type]
    previous_content = params[:previous_content]
    content = params[:content]
    ttl = params[:ttl]
    prio = params[:prio] ||= 0

    db.execute "update records set " +
      "content = '#{content}', ttl = #{ttl}, prio = #{prio} " +
      "where type = '#{type}' " +
      "and content = '#{previous_content}' " +
      "and name = '#{name}'"

    "Record updated."
  end
  
  def delete_record( params )
    db.execute "delete from records " +
      "where type = '#{params[:record_type]}' " +
      "and name = '#{record_name( params )}'"
    "Record deleted."
  end

  private

  # Create the fully-qualified record name from the parameters.
  def record_name( params )
    if params[:name].nil? || params[:name] == ''
      params[:domain] + "."
    else
      "#{params[:name]}.#{params[:domain]}"
    end
  end

end
