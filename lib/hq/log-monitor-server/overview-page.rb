module HQ
module LogMonitorServer

class Script

	def overview_page env

		summaries_by_service =
			get_summaries_by_service

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

end

end
end
