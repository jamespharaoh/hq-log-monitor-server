module HQ
module LogMonitorServer

class Script

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

end

end
end
