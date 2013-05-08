module HQ
module LogMonitorServer

class Script

	def service_host_page env, context

		req = Rack::Request.new env

		source = {
			"class" => context[:class],
			"host" => context[:host],
			"service" => context[:service],
		}

		# process form stuff

		if req.request_method == "POST" \
			&& req.params["mark-all-as-seen"]

			mark_all_as_seen source

		end

		if req.request_method == "POST" \
			&& req.params["delete-all"]

			delete_all source

		end

		# read from database

		events =
			@db["events"]
				.find({
					"source.class" => source["class"],
					"source.host" => source["host"],
					"source.service" => source["service"],
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

		html << "<link href=\"%s\" rel=\"stylesheet\">" % [
			"%s/css/bootstrap-combined.min.css" % [
				@assets_elem["bootstrap"],
			],
		]

		html << "<script src=\"%s\"></script>" % [
			"%s/js/bootstrap.min.js" % [
				@assets_elem["bootstrap"],
			],
		]

		html << "</head>\n"
		html << "<body>\n"

		html << "<div class=\"navbar navbar-static-top\">\n"
		html << "<div class=\"navbar-inner\">\n"
		html << "<div class=\"container\">\n"
		html << "<ul class=\"nav\">\n"
		html << "<li><a href=\"/\">Overview</a></li>\n"
		html << "<li><a href=\"%s\">Service</a></li>\n" % [
			esc_ht("/service/%s" % [
				context[:service],
			]),
		]
		html << "<li class=\"active\"><a href=\"%s\">Host</a></li>\n" % [
			esc_ht("/service/%s/host/%s" % [
				context[:service],
				context[:host],
			])
		]
		html << "</ul>\n"
		html << "</div>\n"
		html << "</div>\n"
		html << "</div>\n"

		html << "<div class=\"container\">\n"
		html << "<div class=\"row\">\n"
		html << "<div class=\"span12\">\n"

		html << "<h1>%s</h1>\n" % [
			esc_ht(title),
		]

		if events.empty?

			html << "<p>No events have been logged for this service on this " +
				"host</p>\n"

		else

			html << "<table id=\"events\" class=\"table table-striped\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Timestamp</th>\n"
			html << "<th>File</th>\n"
			html << "<th>Line</th>\n"
			html << "<th>Type</th>\n"
			html << "<th>Status</th>\n"
			html << "<th>View</th>\n"
			html << "</tr>\n"

			html << "</thead>\n"
			html << "<tbody>\n"

			unseen_count = 0

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
					esc_ht((event["location"]["line"] + 1).to_s),
				]

				html << "<td class=\"type\">%s</td>\n" % [
					esc_ht(event["type"]),
				]

				html << "<td class=\"status\">%s</td>\n" % [
					esc_ht(event["status"]),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/event/%s" % [
							esc_ue(event["_id"].to_s),
						],
					],
				]

				html << "</tr>\n"

				unseen_count += 1 \
					if event["status"] == "unseen"

			end

			html << "</tbody>\n"
			html << "</table>\n"

			html << "<form method=\"post\">\n"

			html << "<p>\n"

			if unseen_count > 0

				html <<
					"<input " +
						"type=\"submit\" " +
						"name=\"mark-all-as-seen\" " +
						"value=\"mark all as seen\">\n"

			end

			html <<
				"<input " +
					"type=\"submit\" " +
					"name=\"delete-all\" " +
					"value=\"delete all\">\n"

			html << "</p>\n"

			html << "</form>\n"

		end

		html << "</div>\n"
		html << "</div>\n"
		html << "</div>\n"

		html << "</body>\n"
		html << "</html>\n"

		return 200, headers, html

	end

end

end
end
