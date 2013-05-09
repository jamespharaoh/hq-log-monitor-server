module HQ
module LogMonitorServer

class Script

	def service_page env, context

		summaries =
			@db["summaries"]
				.find({
					"_id.service" => context[:service]
				})
				.to_a

		summaries.sort_by! {
			|summary|
			[
				summary["_id"]["host"],
				summary["_id"]["class"],
			]
		}

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
		html << "<li class=\"active\"><a href=\"%s\">Service</a></li>\n" % [
			"/service/#{context[:service]}",
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

		if summaries.empty?
			html << "<p>No events have been logged for this service</p>\n"
		else

			html << "<table id=\"summaries\" class=\"table table-striped\">\n"
			html << "<thead>\n"

			html << "<tr>\n"
			html << "<th>Host</th>\n"
			html << "<th>Class</th>\n"
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

				html << "<td class=\"host\">%s</td>\n" % [
					esc_ht(summary["_id"]["host"]),
				]

				html << "<td class=\"service\">%s</td>\n" % [
					esc_ht(summary["_id"]["class"]),
				]

				html << "<td class=\"new\">%s</td>\n" % [
					esc_ht(status_breakdown(summary, "new")),
				]

				html << "<td class=\"total\">%s</td>\n" % [
					esc_ht(status_breakdown(summary, "total")),
				]

				html << "<td class=\"view\">%s</td>\n" % [
					"<a href=\"%s\">view</a>" % [
						"/service-host/%s/%s/%s" % [
							esc_ue(summary["_id"]["service"]),
							esc_ue(summary["_id"]["class"]),
							esc_ue(summary["_id"]["host"]),
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
