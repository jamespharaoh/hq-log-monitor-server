@log-monitor-server
Feature: Log monitor server overview

  Background:

    Given the log monitor server config:
      """
      <log-monitor-server-config>
        <server port="${port}"/>
        <db host="${db-host}" port="${db-port}" name="${db-name}"/>
        <icinga command-file="/dev/null"/>
        <assets bootstrap=""/>
      </log-monitor-server-config>
      """

  Scenario: No events

    When I visit /

    Then I should see no summaries

  Scenario: One summary

    Given I submit the following events:
      """
      {
        type: warning,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: { before: [], matching: WARNING blah, after: [] }
      },
      {
        type: critical,
        source: { class: class, host: host, service: service },
        location: { file: logfile, line: 0 },
        lines: { before: [], matching: CRITICAL blah, after: [] }
      },
      """

    When I visit /

    Then I should see 1 summary
    And the 1st summary should be:
      | name     | value                     |
      | service  | service                   |
      | new      | 2 (1 warning, 1 critical) |
      | total    | 2 (1 warning, 1 critical) |
