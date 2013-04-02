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
		run
	end

	def start
		setup
		Thread.new { run }
	end

	def stop
		@web_server.shutdown
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

	end

	def connect_db

		@mongo =
			Mongo::MongoClient.new \
				@db_elem["host"],
				@db_elem["port"].to_i

		@db =
			@mongo[@db_elem["name"]]

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

		when /^\/service\/([^\/]+)\/host\/([^\/]+)$/
			service_host_page env, :service => $1, :host => $2

		when /^\/event\/([^\/]+)$/
			event_page env, :event_id => $1

		when "/favicon.ico"
			[ 404, {}, [] ]

		else
			raise "Not found: #{env["PATH_INFO"]}"

		end

	end

	def submit_log_event env

		# decode it

		event = MultiJson.load env["rack.input"].read

		# add a timestamp

		event["timestamp"] = Time.now

		# insert it

		@db["events"].insert event

		# update summary

		summary =
			@db["summaries"].find({
				"_id" => event["source"],
			}).first

		summary ||= {
			"_id" => event["source"],
			"combined" => { "new" => 0, "total" => 0 },
			"types" => {},
		}

		summary["types"][event["type"]] ||=
			{ "new" => 0, "total" => 0 }

		summary["types"][event["type"]]["new"] += 1
		summary["types"][event["type"]]["total"] += 1

		summary["combined"]["new"] += 1
		summary["combined"]["total"] += 1

		@db["summaries"].save summary

		# respond successfully

		return 202, {}, []

	end

	def overview_page env

		summaries_by_service = {}

		@db["summaries"].find.each do
			|summary|

			service =
				summary["_id"]["service"]

			summary_by_service =
				summaries_by_service[service] ||= {
					"service" => service,
					"combined" => { "new" => 0, "total" => 0 },
					"types" => {},
				}

			summary_by_service["combined"]["new"] +=
				summary["combined"]["new"]

			summary_by_service["combined"]["total"] +=
				summary["combined"]["total"]

			summary["types"].each do
				|type, type_summary|

				type_summary_by_service =
					summary_by_service["types"][type] ||= {
						"new" => 0,
						"total" => 0,
					}

				type_summary_by_service["new"] +=
					type_summary["new"]

				type_summary_by_service["total"] +=
					type_summary["total"]

			end

		end

		headers = {}
		html = []

		headers["content-type"] = "text/html; charset=utf-8"

		html << "<! DOCTYPE html>\n"
		html << "<html>\n"
		html << "<head>\n"

		title =
			"Overview \u2014 Log monitor"

		html << "<title>%s</title>\n" % [
			esc_ht(title),
		]

		html << "</head>\n"
		html << "<body>\n"

		html << "<h1>%s</h1>\n" % [
			esc_ht(title),
		]

		if summaries_by_service.empty?
			html << "<p>No events have been logged</p>\n"
		else

			html << "<table id=\"summaries\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Service</th>\n"
			html << "<th>Alerts</th>\n"
			html << "<th>Details</th>\n"
			html << "<th>View</th>\n"
			html << "</tr>\n"

			html << "</thead>\n"
			html << "<tbody>\n"

			summaries_by_service.each do
				|service, summary|

				html << "<tr class=\"summary\">\n"

				html << "<td class=\"service\">%s</td>\n" % [
					esc_ht(summary["service"]),
				]

				html << "<td class=\"alerts\">%s</td>\n" % [
					esc_ht(summary["combined"]["new"].to_s),
				]

				html << "<td class=\"detail\">%s</td>\n" % [
					esc_ht(
						summary["types"].map {
							|type, counts|
							"%s %s" % [ counts["new"], type ]
						}.join ", "
					),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/service/%s" % [
							esc_ue(summary["service"]),
						],
					],
				]

				html << "</tr>\n"

			end

			html << "</tbody>\n"
			html << "</table>\n"

		end

		html << "</body>\n"
		html << "</html>\n"

		return 200, headers, html

	end

	def service_page env, context

		summaries =
			@db["summaries"]
				.find({
					"_id.service" => context[:service]
				})
				.to_a

		title =
			"%s - Log monitor" % [
				context[:service],
			]

		headers = {}
		html = []

		headers["content-type"] = "text/html; charset=utf-8"

		html << "<!DOCTYPE html>\n"
		html << "<html>\n"
		html << "<head>\n"

		html << "<title>%s</title>\n" % [
			esc_ht(title),
		]

		html << "</head>\n"
		html << "<body>\n"

		html << "<h1>%s</h1>\n" % [
			esc_ht(title),
		]

		if summaries.empty?
			html << "<p>No events have been logged for this service</p>\n"
		else

			html << "<table id=\"summaries\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Host</th>\n"
			html << "<th>Class</th>\n"
			html << "<th>Alerts</th>\n"
			html << "<th>Details</th>\n"
			html << "<th>View</th>\n"
			html << "</tr>\n"

			html << "</thead>\n"
			html << "<tbody>\n"

			summaries.each do
				|summary|

				html << "<tr class=\"summary\">\n"

				html << "<td class=\"host\">%s</td>\n" % [
					esc_ht(summary["_id"]["host"]),
				]

				html << "<td class=\"service\">%s</td>\n" % [
					esc_ht(summary["_id"]["class"]),
				]

				html << "<td class=\"alerts\">%s</td>\n" % [
					esc_ht(summary["combined"]["new"].to_s),
				]

				html << "<td class=\"detail\">%s</td>\n" % [
					esc_ht(
						summary["types"].map {
							|type, counts|
							"%s %s" % [ counts["new"], type ]
						}.join ", "
					),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/service/%s/host/%s" % [
							esc_ue(summary["_id"]["service"]),
							esc_ue(summary["_id"]["host"]),
						],
					],
				]

				html << "</tr>\n"

			end

			html << "</tbody>\n"
			html << "</table>\n"

		end

		html << "</body>\n"
		html << "</html>\n"

		return 200, headers, html

	end

	def service_host_page env, context

		events =
			@db["events"]
				.find({
					"source.service" => context[:service],
					"source.host" => context[:host],
				})
				.to_a

		title =
			"%s %s \u2014 Log monitor" % [
				context[:host],
				context[:service],
			]

		headers = {}
		html = []

		headers["content-type"] = "text/html; charset=utf-8"

		html << "<!DOCTYPE html>\n"
		html << "<html>\n"
		html << "<head>\n"

		html << "<title>%s</title>\n" % [
			esc_ht(title),
		]

		html << "</head>\n"
		html << "<body>\n"

		html << "<h1>%s</h1>\n" % [
			esc_ht(title),
		]

		if events.empty?
			html << "<p>No events have been logged for this service on this " +
				"host</p>\n"
		else

			html << "<table id=\"events\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Timestamp</th>\n"
			html << "<th>File</th>\n"
			html << "<th>Line</th>\n"
			html << "<th>Type</th>\n"
			html << "<th>View</th>\n"
			html << "</tr>\n"

			html << "</thead>\n"
			html << "<tbody>\n"

			events.each do
				|event|

				html << "<tr class=\"event\">\n"

				html << "<td class=\"timestamp\">%s</td>\n" % [
					esc_ht(event["timestamp"].to_s),
				]

				html << "<td class=\"file\">%s</td>\n" % [
					esc_ht(event["location"]["file"]),
				]

				html << "<td class=\"line\">%s</td>\n" % [
					esc_ht(event["location"]["line"].to_s),
				]

				html << "<td class=\"type\">%s</td>\n" % [
					esc_ht(event["type"]),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/event/%s" % [
							esc_ue(event["_id"].to_s),
						],
					],
				]

				html << "</tr>\n"

			end

			html << "</tbody>\n"
			html << "</table>\n"

		end

		html << "</body>\n"
		html << "</html>\n"

		return 200, headers, html

	end

	def event_page env, context

		event =
			@db["events"]
				.find_one({
					"_id" => BSON::ObjectId.from_string(context[:event_id]),
				})

		title =
			"Event %s \u2014 Log monitor" % [
				context[:event_id],
			]

		headers = {}
		html = []

		headers["content-type"] = "text/html; charset=utf-8"

		html << "<!DOCTYPE html>\n"
		html << "<html>\n"
		html << "<head>\n"

		html << "<title>%s</title>\n" % [
			esc_ht(title),
		]

		html << "</head>\n"
		html << "<body>\n"

		html << "<h1>%s</h1>\n" % [
			esc_ht(title),
		]

		unless event

			html << "<p>Event id not recognised</p>\n"

		else

			html << "<table id=\"event\">\n"
			html << "<tbody>\n"

			html << "<tr>\n"
			html << "<th>ID</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["_id"].to_s),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Timestamp</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["timestamp"].to_s),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Service</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["source"]["service"]),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Host</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["source"]["host"]),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Class</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["source"]["class"]),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Filename</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["location"]["file"]),
			]
			html << "</tr>\n"

			html << "<tr>\n"
			html << "<th>Line number</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht((event["location"]["line"] + 1).to_s),
			]
			html << "</tr>\n"

			unless event["lines"]["before"].empty?

				html << "<tr>\n"
				html << "<th>Before</th>\n"
				html << "<td>%s</td>\n" % [
					event["lines"]["before"]
						.map { |line| esc_ht(line) }
						.join("<br>")
				]

			end

			html << "<tr>\n"
			html << "<th>Matching</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["lines"]["matching"]),
			]

			unless event["lines"]["after"].empty?

				html << "<tr>\n"
				html << "<th>Before</th>\n"
				html << "<td>%s</td>\n" % [
					event["lines"]["after"]
						.map { |line| esc_ht(line) }
						.join("<br>")
				]

			end

			html << "</tbody>\n"
			html << "</table>\n"

		end

		html << "</body>\n"
		html << "</html>\n"

		return 200, headers, html

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
