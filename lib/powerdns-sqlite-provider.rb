require "grape"
require "powerdns-sqlite"

class PowerDNSSQLite::API < Grape::API

  helpers do
    def pdnssql
      @pdnssql = PowerDNSSQLite.new
    end
    
    def authenticate( secret )
      if secret != "some_shared_secret"
        error!('401 Unauthorized', 401)
      end
    end
  end

  resources :domain do
    post :create do
      authenticate( params[:secret] )
      pdnssql.create_domain( params[:domain] )
      pdnssql.list_name_servers( params[:domain] )
    end

    post :delete do
      authenticate( params[:secret] )
      pdnssql.delete_domain( params[:domain] )
    end
  end

  resources :record do
    post :create do
      authenticate( params[:secret] )
      pdnssql.create_record( params )
    end

    post :update do
      authenticate( params[:secret] )
      pdnssql.update_record( params )
    end

    post :delete do
      authenticate( params[:secret] )
      pdnssql.delete_record( params )
    end
  end

end
