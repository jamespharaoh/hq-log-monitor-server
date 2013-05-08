Feature: View and manipulate all events for a service/host combo

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

    And the time is 10

    And I submit the following events:
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
      },
      {
        type: warning,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: {
          before: [],
          matching: WARNING blah,
          after: [],
        }
      },
      """

  Scenario: View the events

    When I visit /service-host/service/class/host

    Then I should see 2 events
    And I should see a button "mark all as seen"
    And I should see a button "delete all"

    And the summary new should be 2
    And the summary total should be 2
    And the summary new for type "warning" should be 2
    And the summary total for type "warning" should be 2

    And icinga should receive:
      """
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 2 warning
      """

  Scenario: Mark all as seen

    Given the time is 20

    When I visit /service-host/service/class/host
    And I click "mark all as seen"

    Then I should see 2 events
    And I should not see a button "mark all as unseen"
    And I should see a button "delete all"

    And the summary new should be 0
    And the summary total should be 2
    And the summary new for type "warning" should be 0
    And the summary total for type "warning" should be 2

    And icinga should receive:
      """
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 2 warning
      [20] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK no new events
      """

  Scenario: Delete all unseen

    Given the time is 20

    When I visit /service-host/service/class/host
    And I click "delete all"

    Then I should not see any events
    And I should not see a button "mark all as seen"
    And I should not see a button "delete all"

    And the summary new should be 0
    And the summary total should be 0
    And the summary new for type "warning" should be 0
    And the summary total for type "warning" should be 0

    And icinga should receive:
      """
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 2 warning
      [20] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK no new events
      """

  Scenario: Delete all seen

    Given the time is 20

    When I visit /service-host/service/class/host
    And I click "mark all as seen"
    And I click "delete all"

    Then I should not see any events
    And I should not see a button "mark all as unseen"
    And I should not see a button "delete all"

    And the summary new should be 0
    And the summary total should be 0
    And the summary new for type "warning" should be 0
    And the summary total for type "warning" should be 0

    And icinga should receive:
      """
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      [10] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 2 warning
      [20] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK no new events
      """
