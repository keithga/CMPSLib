function Test-ForBankersDays {
    <#
    Will return object if day is a Bank Work Day (as compared do a holiday or weekend)

    .EXAMPLE
    1..31 | %{ ([datetime]::Now).AddDays( $_ ) } | Test-ForBankersDays -verbose | %{ $_.ToString('D') }

    #>

    [cmdletbinding()]
    param ( [parameter(Mandatory=$true, ValueFromPipeline=$true)] [dateTime] $Day )

    process {
        if ( $Day.DayOfWeek -in 'Saturday','Sunday' ) {
            #write-verbose "Weekend"
        }
        elseif ( $Day.DayOfYear -eq 1 ) { 
            write-verbose "New Years Day"
        }
        elseif ( $Day.DayOfYear -eq ([datetime]'7/4').DayOfYear ) { 
            write-verbose "4th of July"
        }
        elseif ( $Day.DayOfYear -eq ([datetime]'11/11').DayOfYear ) { 
            write-verbose "Veterans Day"
        }
        elseif ( $Day.DayOfYear -eq ([datetime]'12/25').DayOfYear ) { 
            write-verbose "X-Mas Day"
        }

        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'1/14').AddDays( $_ ) } | ? DayOfWeek -eq 'Monday').DayOfYear  ) { 
            write-verbose "MLK Day"
        }
        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'2/15').AddDays( $_ ) } | ? DayOfWeek -eq 'Monday').DayOfYear  ) { 
            write-verbose "Presidents Day"
        }
        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'5/24').AddDays( $_ ) } | ? DayOfWeek -eq 'Monday').DayOfYear  ) { 
            write-verbose "Memorial Day"
        }
        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'8/31').AddDays( $_ ) } | ? DayOfWeek -eq 'Monday').DayOfYear  ) { 
            write-verbose "Labor Day"
        }
        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'10/7').AddDays( $_ ) } | ? DayOfWeek -eq 'Monday').DayOfYear  ) { 
            write-verbose "Columbus Day"
        }
        elseif ( $Day.DayOfYear -eq (0..6 | %{ ([datetime]'11/21').AddDays( $_ ) } | ? DayOfWeek -eq 'Thursday').DayOfYear  ) { 
            write-verbose "THanksgiving Day"
        }

        else {
            $Day | Write-Output
        }
    }

}

