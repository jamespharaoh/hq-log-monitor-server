# HQ log monitor server

This project provides the server component of the HQ log file monitoring system.

It provides three functions:

- an API for the client part to talk to
- an interface to Icinga or Nagios by writing passive service notifications
- a web UI for end users to interact with

It uses MongoDB for storage of the logged events.

Get it from [GitHub](https://github.com/jamespharaoh/hq-log-monitor-server) or
[RubyGems](https://rubygems.org/gems/hq-log-monitor-server). Check the build
status at [Travis](https://travis-ci.org/jamespharaoh/hq-log-monitor-server).

[![Build Status](https://travis-ci.org/jamespharaoh/hq-log-monitor-server.png)](https://travis-ci.org/jamespharaoh/hq-log-monitor-server)

## Usage

TODO

## API

### Submit event

Events can be submitted to the path /submit-log-event. The HTTP method should be
POST and the Content-Type should be application/json. A status of 202 is
returned on success.

They are expected to be in the following format:

	{
		type: <string>,
		source: {
			class: <string>,
			host: <string>,
			service: <string>,
		},
		location: {
			file: <string>,
			line: <int>,
		},
		lines: {
			before: <string[]>,
			matching: <string>,
			after: <string[]>,
		},
	}

There is currently no way to detect and eliminate duplicates.

## Data format

### Events

These are stored in the "events" collection and store individual events which
have been received.

They look like this:

	{
		_id: <object-id>,
		type: <string>,
		status: "unseen" | "seen",
		source: {
			class: <string>,
			host: <string>,
			service: <string>,
		},
		location: {
			file: <string>,
			line: <int>,
		},
		lines: {
			before: <string[]>,
			matching: <string>,
			after: <string[]>,
		},
		timestamp: <iso-date>,
	}

### Summaries

These are stored in the "summaries" collection and they contain statistics about
the events with a given source.

They look like this:

	{
		_id: {
			class: <string>,
			host: <string>,
			service: <string>,
		},
		combined: {
			new: <int>,
			total: <int>,
		},
		types: {
			...,
			<string>: {
				new: <int>,
				total: <int>,
			},
			...,
		},
	}
