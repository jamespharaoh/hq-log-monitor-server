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

	def mark_all_as_seen source

		# get types

		query = {
			"source.service" => source["service"],
			"source.class" => source["class"],
			"source.host" => source["host"],
			"status" => "unseen",
		}

		types =
			@db["events"].distinct "type", query

		types.each do
			|type|

			# update events

			query = {
				"source.service" => source["service"],
				"source.class" => source["class"],
				"source.host" => source["host"],
				"status" => "unseen",
				"type" => type,
			}

			update = {
				"$set" => {
					"status" => "seen",
				},
			}

			@db["events"].update query, update, :multi => true

			event_count =
				@db.get_last_error["n"]

			# update summaries

			@db["summaries"].update(
				{
					"_id.service" => source["service"],
					"_id.class" => source["class"],
					"_id.host" => source["host"],
				}, {
					"$inc" => {
						"combined.new" => -event_count,
						"types.#{type}.new" => -event_count,
					}
				}
			)

		end

		# notify icinga checks

		do_checks

	end

	def mark_event_as_unseen event_id

		event = get_event event_id

		return if event["status"] == "unseen"

		event["status"] = "unseen"

		@db["events"].save event

		# update summary

		@db["summaries"].update(
			{ "_id" => event["source"] },
			{ "$inc" => {
				"combined.new" => 1,
				"types.#{event["type"]}.new" => 1,
			} }
		)

		# notify icinga checks

		do_checks

	end

	def delete_event event_id

		# fetch it

		event = get_event event_id

		return nil unless event

		# delete it

		@db["events"].remove({
			"_id" => event["_id"],
		})

		event_count =
			@db.get_last_error["n"]

		return event unless event_count > 0

		# update summary

		case event["status"]

		when "unseen"

			@db["summaries"].update(
				{ "_id" => event["source"] },
				{ "$inc" => {
					"combined.new" => -1,
					"combined.total" => -1,
					"types.#{event["type"]}.new" => -1,
					"types.#{event["type"]}.total" => -1,
				} }
			)

		when "seen"

			@db["summaries"].update(
				{ "_id" => event["source"] },
				{ "$inc" => {
					"combined.total" => -1,
					"types.#{event["type"]}.total" => -1,
				} }
			)

		else

			raise "Error 3084789190"

		end

		# notify icinga checks

		do_checks

		# and return

		return event

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
