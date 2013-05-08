Feature: View and manipulate a single event

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
      </log-monitor-server-config>
      """

    And the time is 100

    And I submit the following event:
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

  Scenario: View an event

    When I visit /event/${event-id}

    Then I should see the event
    And the event status should be "unseen"

    And the summary new should be 1
    And the summary total should be 1
    And the summary new for type "warning" should be 1
    And the summary total for type "warning" should be 1

Scenario: Mark as seen

    Given the time is 200

    When I visit /event/${event-id}
    And I click "mark as seen"

    Then I should see the event
    And the event status should be "seen"

    And the summary new should be 0
    And the summary total should be 1
    And the summary new for type "warning" should be 0
    And the summary total for type "warning" should be 1

    And icinga should receive:
      """
      [100] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK no new events
      [100] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      [200] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK no new events
      """
