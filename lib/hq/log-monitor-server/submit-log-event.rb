module HQ
module LogMonitorServer

class Script

	def submit_log_event env

		# decode it

		event = MultiJson.load env["rack.input"].read

		# add some fields

		event["timestamp"] = Time.now
		event["status"] = "unseen"

		# insert it

		@db["events"].insert event

		# update summary

		summary =
			@db["summaries"].find({
				"_id" => event["source"],
			}).first

		summary ||= {
			"_id" => event["source"],
			"combined" => { "new" => 0, "total" => 0 },
			"types" => {},
		}

		summary["types"][event["type"]] ||=
			{ "new" => 0, "total" => 0 }

		summary["types"][event["type"]]["new"] += 1
		summary["types"][event["type"]]["total"] += 1

		summary["combined"]["new"] += 1
		summary["combined"]["total"] += 1

		@db["summaries"].save summary

		# perform checks

		do_checks

		# respond successfully

		return 202, {}, []

	end

end

end
end
