require "hq/log-monitor-server/misc"

module HQ
module LogMonitorServer

describe Script do

	context "#status_breakdown" do

		it "shows 0 if the combined amount is 0" do
			summary = {
				"combined" => { "new" => 0 },
			}
			ret = subject.status_breakdown summary, "new"
			ret.should == "0"
		end

		it "shows a breakdown if the combined amount is greater than 0" do
			summary = {
				"combined" => { "new" => 3 },
				"types" => {
					"type1" => { "new" => 1 },
					"type2" => { "new" => 2 },
				},
			}
			ret = subject.status_breakdown summary, "new"
			ret.should == "3 (1 type1, 2 type2)"
		end

	end

	context "#level_for_type" do

		before do
			require "xml"
		end

		it "returns nil if the service does not exist" do
			
			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("<icinga/>")

			ret = subject.level_for_type "service", "type"

			ret.should == nil

		end

		it "returns nil if the type does not exist" do
			
			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("
					<icinga>
						<service name=\"service\"/>
					</icinga>
				")

			ret = subject.level_for_type "service", "type"

			ret.should == nil

		end

		it "returns nil if the type has no level" do
			
			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("
					<icinga>
						<service name=\"service\">
							<type name=\"type\"/>
						</service>
					</icinga>
				")

			ret = subject.level_for_type "service", "type"

			ret.should == nil

		end

		it "returns nil if the type has an empty level" do
			
			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("
					<icinga>
						<service name=\"service\">
							<type name=\"type\" level=\"\"/>
						</service>
					</icinga>
				")

			ret = subject.level_for_type "service", "type"

			ret.should == nil

		end

		it "returns the appropriate level if all is well" do
			
			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("
					<icinga>
						<service name=\"service\">
							<type name=\"type\" level=\"level\"/>
						</service>
					</icinga>
				")

			ret = subject.level_for_type "service", "type"

			ret.should == "level"

		end

	end

	context "#level_for_summary" do

		before do

			subject.instance_variable_set \
				"@icinga_elem",
				XML::Document.string("
					<icinga>
						<service name=\"service\">
							<type name=\"critical\" level=\"critical\"/>
							<type name=\"warning\" level=\"warning\"/>
						</service>
					</icinga>
				")

		end

		it "returns critical if any are critical" do

			summary = {
				"_id" => {
					"service" => "service",
				},
				"types" => {
					"critical" => { "new" => 1 },
					"warning" => { "new" => 1 },
					"other" => { "new" => 1 },
				},
			}

			ret = subject.level_for_summary summary

			ret.should == "critical"

		end

		it "returns warning if any are warning but none are critical" do

			summary = {
				"_id" => {
					"service" => "service",
				},
				"types" => {
					"warning" => { "new" => 1 },
					"other" => { "new" => 1 },
				},
			}

			ret = subject.level_for_summary summary

			ret.should == "warning"

		end

		it "returns nil if there none are warning or critical" do

			summary = {
				"_id" => {
					"service" => "service",
				},
				"types" => {
					"other" => { "new" => 1 },
				},
			}

			ret = subject.level_for_summary summary

			ret.should be_nil

		end

	end

end

end
end
