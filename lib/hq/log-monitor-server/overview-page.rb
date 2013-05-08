module HQ
module LogMonitorServer

class Script

	def overview_page env

		summaries_by_service =
			get_summaries_by_service

		headers = {}
		html = []

		headers["content-type"] = "text/html; charset=utf-8"

		html << "<!DOCTYPE html>\n"
		html << "<html>\n"
		html << "<head>\n"

		title =
			"Overview \u2014 Log monitor"

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
		html << "<li class=\"active\"><a href=\"/\">Overview</a></li>\n"
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

		if summaries_by_service.empty?
			html << "<p>No events have been logged</p>\n"
		else

			html << "<table class=\"table table-striped\" id=\"summaries\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Service</th>\n"
			html << "<th>New</th>\n"
			html << "<th>Total</th>\n"
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

				html << "<td class=\"new\">%s</td>\n" % [
					esc_ht(
						summary["combined"]["new"] > 0 ? "%s (%s)" % [
							esc_ht(summary["combined"]["new"].to_s),
							summary["types"]
								.select {
									|type, counts|
									counts["new"] > 0
								}
								.map {
									|type, counts|
									"%s %s" % [ counts["new"], type ]
								}
								.join(", ")
						] : "0"
					),
				]

				html << "<td class=\"total\">%s</td>\n" % [
					esc_ht(
						summary["combined"]["total"] > 0 ? "%s (%s)" % [
							esc_ht(summary["combined"]["total"].to_s),
							summary["types"]
								.select {
									|type, counts|
									counts["total"] > 0
								}
								.map {
									|type, counts|
									"%s %s" % [ counts["total"], type ]
								}
								.join(", ")
						] : "0"
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
