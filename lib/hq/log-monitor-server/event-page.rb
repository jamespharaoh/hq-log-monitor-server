module HQ
module LogMonitorServer

class Script

	def event_page env, context

		req = Rack::Request.new env

		# process form stuff

		if req.request_method == "POST" \
			&& req.params["mark-as-seen"]

			mark_event_as_seen context[:event_id]

		end

		if req.request_method == "POST" \
			&& req.params["mark-as-unseen"]

			mark_event_as_unseen context[:event_id]

		end

		# read from database

		event =
			@db["events"]
				.find_one({
					"_id" => BSON::ObjectId.from_string(context[:event_id]),
				})

		# set headers

		headers = {}

		headers["content-type"] = "text/html; charset=utf-8"

		# create page

		html = []

		title =
			"Event %s \u2014 Log monitor" % [
				context[:event_id],
			]

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
			html << "<th>Status</th>\n"
			html << "<td>%s</td>\n" % [
				esc_ht(event["status"].to_s),
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
				esc_ht((event["location"]["line"].to_i + 1).to_s),
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

		html << "<form method=\"post\">\n"

		html << "<p>\n"

		if event["status"] != "seen"

			html <<
				"<input " +
					"type=\"submit\" " +
					"name=\"mark-as-seen\" " +
					"value=\"mark as seen\">\n"

		end

		if event["status"] != "unseen"

			html <<
				"<input " +
					"type=\"submit\" " +
					"name=\"mark-as-unseen\" " +
					"value=\"mark as unseen\">\n"

		end

		html << "</p>\n"

		html << "</form>\n"

		html << "</body>\n"
		html << "</html>\n"

		# return

		return 200, headers, html

	end

end

end
end
