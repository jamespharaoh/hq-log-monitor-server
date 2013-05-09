require "mongo"
require "multi_json"
require "rack"
require "webrick"
require "xml"

require "hq/tools/escape"
require "hq/tools/getopt"

module HQ
module LogMonitorServer

class Script

	include Tools::Escape

	attr_accessor :args
	attr_accessor :status

	def initialize
		@status = 0
	end

	def main
		setup
		trap "INT" do
			@web_server.shutdown
		end
		Thread.new { background }
		run
	end

	def start
		setup
		Thread.new { run }
		@background_thread = Thread.new { background }
	end

	def stop
		@web_server.shutdown
		stop_checks
	end

	def setup
		process_args
		read_config
		connect_db
		init_server
	end

	def run
		@web_server.start
	end

	def process_args

		@opts, @args =
			Tools::Getopt.process @args, [

			{ :name => :config,
				:required => true },

			{ :name => :quiet,
				:boolean => true },

		]

		@args.empty? \
			or raise "Extra args on command line"

	end

	def read_config

		config_doc =
			XML::Document.file @opts[:config]

		@config_elem =
			config_doc.root

		@server_elem =
			@config_elem.find_first("server")

		@db_elem =
			@config_elem.find_first("db")

		@icinga_elem =
			@config_elem.find_first("icinga")

		@assets_elem =
			@config_elem.find_first("assets")

	end

	def connect_db

		@mongo =
			Mongo::MongoClient.new \
				@db_elem["host"],
				@db_elem["port"].to_i

		@db =
			@mongo[@db_elem["name"]]

		@db["events"].ensure_index \
			"source.service" => Mongo::ASCENDING,
			"source.class" => Mongo::ASCENDING,
			"source.host" => Mongo::ASCENDING,
			"timestamp" => Mongo::ASCENDING

	end

	def init_server

		@web_config = {
			:Port => @server_elem["port"].to_i,
			:AccessLog => [],
		}

		if @opts[:quiet]
			@web_config.merge!({
				:Logger => WEBrick::Log::new("/dev/null", 7),
				:DoNotReverseLookup => true,
			})
		end

		@web_server =
			WEBrick::HTTPServer.new \
				@web_config

		@web_server.mount "/", Rack::Handler::WEBrick, self

	end

	def call env

		case env["PATH_INFO"]

		when "/submit-log-event"
			submit_log_event env

		when "/"
			overview_page env

		when /^\/service\/([^\/]+)$/
			service_page env, :service => $1

		when /^\/service-host\/([^\/]+)\/([^\/]+)\/([^\/]+)$/
			service_host_page env, :service => $1, :class => $2, :host => $3

		when /^\/event\/([^\/]+)$/
			event_page env, :event_id => $1

		when "/favicon.ico"
			[ 404, {}, [] ]

		else
			raise "Not found: #{env["PATH_INFO"]}"

		end

	end

	def sf format, *args

		ret = []

		format.scan(/%.|%%|[^%]+|%/).each do
			|match|

			case match

			when ?%
				raise "Error"

			when "%%"
				ret << ?%

			when /^%(.)$/
				ret << send("format_#{$1}", args.shift)

			else
				ret << match

			end

		end

		return ret.join

	end

end

end
end

# extra bits

require "hq/log-monitor-server/do-checks"
require "hq/log-monitor-server/event-page"
require "hq/log-monitor-server/logic"
require "hq/log-monitor-server/misc"
require "hq/log-monitor-server/overview-page"
require "hq/log-monitor-server/service-host-page"
require "hq/log-monitor-server/service-page"
require "hq/log-monitor-server/submit-log-event"
