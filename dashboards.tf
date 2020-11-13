locals {
  syslog              = "syslog-rfc5424"
  severity            = "(numeric(pri) - (floor(numeric(pri)/8) * 8))"

  severity_billboards = tomap({
    "emergency"     = { severity =  0, row = 1, column = 1, threshold_red = 1 },
    "alert"         = { severity =  1, row = 2, column = 1, threshold_red = 1 },
    "critical"      = { severity =  2, row = 1, column = 2, threshold_red = 1 },
    "error"         = { severity =  3, row = 2, column = 2, threshold_yellow = 1 },
    "warning"       = { severity =  4, row = 1, column = 3 },
    "notice"        = { severity =  5, row = 2, column = 3 },
    "informational" = { severity =  6, row = 1, column = 4 },
    "debug"         = { severity =  7, row = 2, column = 4 }
  })
}

resource "newrelic_dashboard" "syslog_dashboard" {
  title             = "Syslog Dashboard"
  grid_column_count = 12

  dynamic "widget" {
    for_each = local.severity_billboards
    content {
      title            = ""
      nrql             = <<-EOF
        SELECT
          count(*) as '${title(widget.key)} (${widget.value.severity})'
        FROM Log
        WHERE logType = '${local.syslog}' AND ${local.severity} = ${widget.value.severity}
      EOF
      visualization    = "billboard"
      width            = 1
      height           = 1
      row              = widget.value.row
      column           = widget.value.column
      threshold_yellow = try(widget.value.threshold_yellow, null)
      threshold_red    = try(widget.value.threshold_red, null)
    }
  }

  widget {
    title         = "Throughput"
    nrql          = <<-EOF
      SELECT
        rate(count(*), 1 minute) as 'Logs /min',
        count(*) as 'Total'
      FROM Log 
      WHERE logType = '${local.syslog}' SINCE 1 hour ago
    EOF
    visualization = "attribute_sheet"
    width         = 2
    height        = 2
    row           = 1
    column        = 5
  }

  widget {
    title         = "Top Applications"
    nrql          = <<-EOF
      SELECT
        count(*)
      FROM Log
      WHERE logType = '${local.syslog}'
      FACET app.name
    EOF
    visualization = "facet_bar_chart"
    width         = 2
    height        = 5
    row           = 1
    column        = 7
  }

  widget {
    title         = "Top Nodes"
    nrql          = <<-EOF
      SELECT
        count(*) as 'Logs'
      FROM Log
      WHERE logType = '${local.syslog}'
      FACET hostname
    EOF
    visualization = "facet_bar_chart"
    width         = 2
    height        = 5
    row           = 1
    column        = 9
  }

  widget {
    title         = ""
    width         = 2
    height        = 5
    row           = 1
    column        = 11
    source        = <<-EOF
    ### Facilities
    0. kernel messages
    1. user-level messages
    2. mail system
    3. system daemons
    4. security/authorization messages (note 1)
    5. messages generated internally by syslogd
    6. line printer subsystem
    7. network news subsystem
    8. UUCP subsystem
    9. clock daemon (note 2)
    10. security/authorization messages (note 1)
    11. FTP daemon
    12. NTP subsystem
    13. log audit (note 1)
    14. log alert (note 1)
    15. clock daemon (note 2)
    16. to 23. local uses 0 to 7 (local n)
    EOF
    visualization = "markdown"
  }

  widget {
    title         = "Logs (Emergency + Alert + Critical + Error)"
    nrql          = <<-EOF
      SELECT
        count(*)
      FROM Log
      WHERE logType = '${local.syslog}' AND ${local.severity} < 4
      TIMESERIES AUTO
    EOF
    visualization = "line_chart"
    width         = 6
    height        = 3
    row           = 3
    column        = 1
  }

  widget {
    title         = "Logs by Severity"
    nrql          = <<-EOF
      SELECT
        count(*)
      FROM Log
      WHERE logType = '${local.syslog}'
      FACET string(${local.severity}) as 'Severity'
      TIMESERIES AUTO
    EOF
    visualization = "faceted_line_chart"
    width         = 3
    height        = 3
    row           = 6
    column        = 1
  }

  widget {
    title         = "Logs by Facility"
    nrql          = <<-EOF
      SELECT
        count(*)
      FROM Log
      WHERE logType = '${local.syslog}'
      FACET floor(numeric(pri)/8) as 'Facility'
      TIMESERIES AUTO
    EOF
    visualization = "faceted_line_chart"
    width         = 3
    height        = 3
    row           = 6
    column        = 4
  }

  widget {
    title         = "Top 100 Logs"
    nrql          = <<-EOF
      SELECT
          ${local.severity} as 'Severity',
          app.name as 'Application',
          message
      FROM Log
      WHERE logType = '${local.syslog}' LIMIT 100
    EOF
    column        = 7
    row           = 6
    visualization = "event_table"
    width         = 6
    height        = 3
  }
}