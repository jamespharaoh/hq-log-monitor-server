module HQ
module LogMonitorServer

class Script

	def get_event event_id

		return @db["events"].find({
			"_id" => BSON::ObjectId.from_string(event_id),
		}).first

	end

	def mark_event_as_seen event_id

		event = get_event event_id

		return if event["status"] == "seen"

		event["status"] = "seen"

		@db["events"].save event

		# update summary

		@db["summaries"].update(
			{ "_id" => event["source"] },
			{ "$inc" => {
				"combined.new" => -1,
				"types.#{event["type"]}.new" => -1,
			} }
		)

		# notify icinga checks

		do_checks

	end

	def get_summaries_by_service

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

		return summaries_by_service

	end

end

end
end
