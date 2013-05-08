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

end

end
end
