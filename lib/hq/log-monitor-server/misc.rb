module HQ
module LogMonitorServer

class Script

	def status_breakdown summary, status

		if summary["combined"][status] == 0

			return "0"

		else

			return "%s (%s)" % [

				summary["combined"][status].to_s,

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

			]

		end

	end

end

end
end
