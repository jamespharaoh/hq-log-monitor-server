@log-monitor-server
Feature: Icinga updates

  Background:

    Given the log monitor server config:
      """
      <log-monitor-server-config>
        <server port="${port}"/>
        <db host="${db-host}" port="${db-port}" name="${db-name}"/>
        <icinga command-file="${command-file}">
          <service name="service" icinga-host="host" icinga-service="service">
            <type name="none" level="none"/>
            <type name="warning" level="warning"/>
            <type name="critical" level="critical"/>
          </service>
        </icinga>
        <assets bootstrap=""/>
      </log-monitor-server-config>
      """

    And the time is 123456

  Scenario: Level none

    When I submit the following event:
      """
      {
        type: none,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: {
          before: [],
          matching: NONE blah,
          after: [],
        }
      }
      """

    Then icinga should receive:
      """
      [123456] PROCESS_SERVICE_CHECK_RESULT;host;service;0;OK 1 other
      """

  Scenario: Level warning

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

    Then icinga should receive:
      """
      [123456] PROCESS_SERVICE_CHECK_RESULT;host;service;1;WARNING 1 warning
      """

  Scenario: Level warning

    When I submit the following event:
      """
      {
        type: critical,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: {
          before: [],
          matching: CRITICAL blah,
          after: [],
        }
      }
      """

    Then icinga should receive:
      """
      [123456] PROCESS_SERVICE_CHECK_RESULT;host;service;2;CRITICAL 1 critical
      """
