require "monit_request_client/version"
require "hashie"

module MonitRequestClient
  class Error < StandardError;
  end
  # Your code goes here...
  require 'bunny'
  class Statistic

    def initialize(app)
      begin
        @config = Hashie::Mash.new YAML.load_file(Rails.root.join('config', 'dashboard.yml'))
        if @config["collect_data"] == false
          @app = app
          return
        end
        conn = Bunny.new(@config["connect"])
        conn.start
        channel = conn.create_channel
        @queue = channel.queue(@config["queue_name"], durable: true)
        @exchange  = channel.default_exchange
        rescue => e
        end
      @app = app
    end

    def call(env)
      start = (Time.now.to_f * 1000).to_i
      trace = ""
      exception_message = ""
      code = ""
      begin
        status, headers, response = @app.call(env)
      rescue => e
        trace = e.backtrace.join(",")
        exception_message = e.message
        raise e
      ensure
        request = ::Rack::Request.new(env)
        if @config && @config["collect_data"] == true && request.path.start_with?(@config["path_prifex"])

          Thread.new do
            begin
              begin
                # api code for record
                if response && headers && headers["Content-Type"].include?("application/json")
                  body = JSON.parse(response.body.dup)
                  if body && body["head"] && body["head"]["code"]
                    code = body["head"]["code"]
                  end
                end
              rescue => e
              end
              stop = (Time.now.to_f * 1000).to_i
              data = {"path" => request.path}
              data["method"] = request.request_method
              if env["rack.methodoverride.original_method"].present?
                data["method"] = env["rack.methodoverride.original_method"]
              end
              data["error_code"] = code
              params = request.params.dup
              # add routes params
              if env["action_dispatch.request.parameters"].present?
                params = params.merge(env["action_dispatch.request.parameters"])
              end
              params.delete("_method")
              params.delete("authenticity_token")
              data["params"] = params.to_query
              data["start_time"] = start
              data["end_time"] = stop
              data["exception"] = exception_message
              data["exception_content"] = trace
              fwd = env['HTTP_X_FORWARDED_FOR']
              if fwd
                ip = fwd.strip.split(/[,\s]+/)[0] # stolen from Rack::Request#split_ip_addresses
              else
                ip = env['HTTP_X_REAL_IP'] || env['REMOTE_ADDR']
              end
              data["ip"] = ip
              data["user_id"] = env["current_user_id"]
              data["user_agent"] = request.user_agent
              data["uuid"] = env["HTTP_UUID"] if env["HTTP_UUID"]
              @exchange.publish(data.to_json, :routing_key => @queue.name,:persistent => true, :content_type => "text/plain")
            rescue => e
            end
          end
        end
      end
      [status, headers, response]
    end
  end
end
