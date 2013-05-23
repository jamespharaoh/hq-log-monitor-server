module HQ
module LogMonitorServer

class Script

	CHECK_FREQUENCY = 60

	def background

		@mutex = Mutex.new
		@run_now_signal = ConditionVariable.new
		@next_check_done_signal = nil
		@current_check_done_signal = nil
		@stop_checks_signal = nil

		@next_check = Time.now

		loop do

			# wait till next invocation

			@mutex.synchronize do

				until @next_check_done_signal

					if @next_check < Time.now
						@next_check_done_signal = ConditionVariable.new
						break
					end

					@run_now_signal.wait @mutex, 1

					if @stop_checks_signal
						@stop_checks_signal.broadcast
						return
					end

				end

				@current_check_done_signal = @next_check_done_signal

			end

			# perform the checks

			begin
				do_checks_real
			rescue => e
				$stderr.puts e, *e.backtrace
				sleep 10
			ensure

				# notify waiting threads

				@mutex.synchronize do

					if @next_check_done_signal == @current_check_done_signal
						@next_check_done_signal = nil
					end

					@current_check_done_signal.broadcast

				end

			end

			@next_check = Time.now + CHECK_FREQUENCY

		end

	end

	def stop_checks

		@mutex.synchronize do

			unless @stop_checks_signal
				@stop_checks_signal = ConditionVariable.new
			end

			@run_now_signal.signal

			@stop_checks_signal.wait @mutex

		end

	end

	def do_checks

		@mutex.synchronize do

			if @next_check_done_signal

				# next run already scheduled, just wait for it

				@next_check_done_signal.wait @mutex

			else

				# create new next run and wait for it

				@next_check_done_signal = ConditionVariable.new

				@run_now_signal.signal

				@next_check_done_signal.wait @mutex

			end

		end

	end

	def do_checks_real

		File.open @icinga_elem["command-file"], "a" do
			|command_io|

			summaries_by_service =
				get_summaries_by_service

			@icinga_elem.find("service").each do
				|service_elem|

				service_name = service_elem["name"]

				critical_count = 0
				warning_count = 0
				other_count = 0
				unknown_count = 0

				summaries =
					summaries_by_service[service_name]

				if summaries
					summaries["types"].each do
						|type_name, type_info|

						case level_for_type service_name, type_name
							when "critical"
								critical_count += type_info["new"]
							when "warning"
								warning_count += type_info["new"]
							when "none"
								other_count += type_info["new"]
							else
								unknown_count += type_info["new"]
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

				if other_count > 0
					parts << "%d other" % other_count
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

	end

end

end
end
