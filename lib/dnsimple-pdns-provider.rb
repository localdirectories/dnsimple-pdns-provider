require "grape"
require "yaml"
require "dnsimple-pdns"

module DNSimple
  class Pdns::API < Grape::API

    helpers do
      def config
        @config ||= YAML.load_file( ENV["pdns.config"] )
      end

      def pdns
        @pdns = Pdns.new( config["db"], config["nameservers"] )
      end

      def authenticate( secret )
        if secret != config["shared_secret"]
          error!( "401 Unauthorized", 401 )
        end
      end
    end

    resources :domain do
      post :create do
        authenticate( params[:secret] )
        pdns.create_domain( params[:domain] )
        pdns.list_name_servers( params[:domain] )
      end

      post :delete do
        authenticate( params[:secret] )
        pdns.delete_domain( params[:domain] )
      end
    end

    resources :record do
      post :create do
        authenticate( params[:secret] )
        pdns.create_record( params )
      end

      post :update do
        authenticate( params[:secret] )
        pdns.update_record( params )
      end

      post :delete do
        authenticate( params[:secret] )
        pdns.delete_record( params )
      end
    end

  end
end
