require "hq/tools/escape"

module HQ
module LogMonitorServer

class Script

	include Tools::Escape

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

	def level_for_type service_name, type_name

		service_elem =
			@icinga_elem.find_first("
				service [@name = #{esc_xp service_name}]
			")

		return nil unless service_elem

		type_elem =
			service_elem.find_first("
				type [@name = #{esc_xp type_name}]
			")

		return nil unless type_elem

		level = type_elem["level"]

		return level == "" ? nil : level


	end

	def class_for_level level

		case level

			when "critical"
				return "error"

			when "warning"
				return "warning"

		end

	end

	def class_for_type service, type

		level = level_for_type service, type

		return class_for_level level

	end

	def class_for_event event

		return nil \
			unless event["status"] == "unseen"

		return class_for_type \
			event["source"]["service"],
			event["type"]

	end

	def level_for_summary summary

		critical = false
		warning = false

		summary["types"].each do
			|type_name, type_info|

			next unless type_info["new"] > 0

			case level_for_type summary["_id"]["service"], type_name

			when "critical"
				critical = true

			when "warning"
				warning = true

			end

		end

		return "critical" if critical
		return "warning" if warning

		return nil

	end

	def class_for_summary summary

		level = level_for_summary summary

		return class_for_level level

	end

end

end
end
