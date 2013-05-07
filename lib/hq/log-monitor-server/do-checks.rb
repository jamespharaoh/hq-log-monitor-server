module HQ
module LogMonitorServer

class Script

	def do_checks
		@mutex.synchronize do

			File.open @icinga_elem["command-file"], "a" do
				|command_io|

				summaries_by_service =
					get_summaries_by_service

				@icinga_elem.find("service").each do
					|service_elem|

					service_name = service_elem["name"]

					critical_count = 0
					warning_count = 0
					unknown_count = 0

					summaries =
						summaries_by_service[service_name]

					if summaries
						summaries["types"].each do
							|type_name, type_info|

							type_elem =
								service_elem.find_first("
									type [@name = #{esc_xp type_name}]
								")

							if ! type_elem
								unknown_count += 1
							elsif type_elem["level"] == "critical"
								critical_count += 1
							elsif type_elem["level"] == "warning"
								warning_count += 1
							else
								unknown_count += 1
							end
						end
					end

					status_int =
						if critical_count > 0
							2
						elsif warning_count > 0
							1
						elsif unknown_count > 0
							3
						else
							0
						end

					status_str =
						if critical_count > 0
							"CRITICAL"
						elsif warning_count > 0
							"WARNING"
						elsif unknown_count > 0
							"UNKNOWN"
						else
							"OK"
						end

					parts = []

					if critical_count > 0
						parts << "%d critical" % critical_count
					end

					if warning_count > 0
						parts << "%d warning" % warning_count
					end

					if unknown_count > 0
						parts << "%d unknown" % unknown_count
					end

					if parts.empty?
						parts << "no new events"
					end


					command_io.print "[%s] %s\n" % [
						Time.now.to_i,
						[
							"PROCESS_SERVICE_CHECK_RESULT",
							service_elem["icinga-host"],
							service_elem["icinga-service"],
							status_int,
							"%s %s" % [
								status_str,
								parts.join(", "),
							]
						].join(";"),
					]

				end

			end

			@next_check = Time.now + 60

		end

	end

end

end
end
