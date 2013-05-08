@log-monitor-server
Feature: Log monitor server submit event via HTTP

  Background:

    Given the log monitor server config:
      """
      <log-monitor-server-config>
        <server port="${port}"/>
        <db host="${db-host}" port="${db-port}" name="${db-name}"/>
        <icinga command-file="${command-file}">
          <service name="service" icinga-host="host" icinga-service="service">
            <type name="warning" level="warning"/>
            <type name="critical" level="critical"/>
          </service>
        </icinga>
        <assets bootstrap=""/>
      </log-monitor-server-config>
      """

    And the time is 123456

  Scenario: Submit event

    When I submit the following event:
      """
      {
        type: warning,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: {
          before: [],
          matching: WARNING blah,
          after: [],
        }
      }
      """

    Then I should receive a 202 response
    And the event should be in the database
    And the summary should show:
      """
      {
        _id: { class: class, host: host, service: service },
        combined: { new: 1, total: 1 },
        types: {
          warning: { new: 1, total: 1 },
        },
      }
      """
    And icinga should receive:
      """
      [123456] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      """
