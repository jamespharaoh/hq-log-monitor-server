module HQ
module LogMonitorServer

class Script

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

			html << "<tr id=\"id\">\n"
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

end

end
end
