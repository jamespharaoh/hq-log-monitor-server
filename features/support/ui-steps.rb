When /^I visit (\/.*)$/ do
	|url_raw|

	url = url_raw.gsub /\$\{([-a-z]+)\}/ do
		var_name = $1.gsub "-", "_"
		instance_variable_get "@#{var_name}"
	end

	visit url

end

When /^I click "(.*?)"$/ do
	|target_str|

	click_on target_str

end

Then /^I should see no summaries$/ do
	page.should have_content "No events have been logged"
end

Then /^I should see (\d+) summar(?:y|ies)$/ do
	|count_str|
	count = count_str.to_i
	find("#summaries").should have_css(".summary", :count => count)
end

Then /^the (\d+(?:st|nd|rd|th)) summary should be:$/ do
	|index_str, fields|

	index = index_str.to_i

	within "#summaries" do

		fields.hashes.each do
			|row|
			find(".#{row["name"]}").text.should == row["value"]
		end

	end

end

Then /^icinga should receive:$/ do
	|expected_command|

	command_contents =
		File.new(@command_file).to_a.map { |line| line.strip }

	command_contents.should \
		include expected_command

end

Then /^I should see the event$/ do

	find("#event #id td").text.should == @event_id.to_s

end