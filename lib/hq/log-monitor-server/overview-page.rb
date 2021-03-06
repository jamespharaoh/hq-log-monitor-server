module HQ
module LogMonitorServer

class Script

	def overview_page env

		summaries_by_service =
			get_summaries_by_service

		summaries =
			summaries_by_service
				.values
				.sort_by { |summary| summary["_id"]["service"] }

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

		if summaries.empty?
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

			summaries.each do
				|summary|

				html << "<tr class=\"%s\">\n" % [
					esc_ht([
						"summary",
						class_for_summary(summary),
					].compact.join(" "))
				]

				html << "<td class=\"service\">%s</td>\n" % [
					esc_ht(summary["_id"]["service"]),
				]

				html << "<td class=\"new\">%s</td>\n" % [
					esc_ht(status_breakdown(summary, "new")),
				]

				html << "<td class=\"total\">%s</td>\n" % [
					esc_ht(status_breakdown(summary, "total")),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/service/%s" % [
							esc_ue(summary["_id"]["service"]),
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
