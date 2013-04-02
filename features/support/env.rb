require "capybara/cucumber"
require "mongo"
require "net/http"

require "hq/log-monitor-server/script"

$token = (?a..?z).to_a.sample(10).join

# database stuff

$db_names = []

Before do
	@db_names = []
end

def mongo_db_name name
	if @db_names
		@db_names << name unless @db_names.include? name
	end
	$db_names << name unless $db_names.include? name
	"cuke_#{$token}_#{name}"
end

def mongo_conn
	return $mongo if $mongo
	$mongo = Mongo::MongoClient.new "localhost", 27017
	return $mongo
end

def mongo_db name
	mongo_conn[mongo_db_name name]
end

After do

	@db_names.each do
		|db_name|

		mongo_db(db_name).collections.each do
			|coll|
			next if coll.name =~ /^system\./
			coll.drop
		end

	end

end

at_exit do

	$db_names.each do
		|db_name|

		mongo_conn.drop_database mongo_db_name(db_name)

	end

end
