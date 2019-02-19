require "monit_request_client/version"

module MonitRequestClient
  class Error < StandardError;
  end
  # Your code goes here...
  require 'bunny'
  class Statistic

    def initialize(app)
      @config = YAML.load_file(Rails.root.join('config', 'dashboard.yml'))
      if @config["collect_data"] == false
        @app = app
        return
      end
      conn = Bunny.new(@config["connect"])
      conn.start
      channel = conn.create_channel
      @queue = channel.queue(@config["queue_name"])
      @app = app
    end

    def call(env)
      start = Time.now
      request = ::Rack::Request.new(env)
      trace = ""
      exception_message = ""
      code = ""
      begin
        status, headers, response = @app.call(env)
      rescue => e
        trace = e.backtrace
        exception_message = e.message
        raise e
      ensure
        if @config["collect_data"] == true && request.path.start_with?(@config["path_prifex"])

          Thread.new do
            begin
              begin
                if response && request.format == "json"
                  body = JSON.parse(response.body)["head"]["code"]
                  if body && body["head"] && body["head"]["code"]
                    code = body["head"]["code"]
                  end
                end
              rescue => e
              end
              stop = Time.now
              data = {"path" => request.path}
              data["method"] = request.request_method
              data["error_code"] = code
              data["params"] = request.params
              data["start_time"] = start
              data["end_time"] = stop
              data["exception"] = exception_message
              data["exception_content"] = trace
              data["ip"] = request.ip
              data["user_id"] = env["current_user_id"]
              data["user_agent"] = request.user_agent
              @queue.publish(data.to_json)
            rescue => e
            end
          end
        end
      end
      [status, headers, response]
    end
  end
end
