# time manipulation which doesn't break background threads

Before do

	original_now = Time.method(:now)

	@set_time = nil

	Time.stub(:now) do
		if @set_time
			@set_time
		else
			original_now.call
		end
	end

end

def set_time new_time
	@set_time = new_time
end
