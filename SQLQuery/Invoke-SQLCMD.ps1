
Function Invoke-SQLCMD {
    <#
    Exmaple 

    Invoke-SQLCmd -HostName CM1 -Database 'ConfigMgr_CHQ' -SQLQuery 'SELECT CollectionID,SIteID,CollectionName FROM [dbo].[Collections] WHERE CollectionType = 2'

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string] $HostName,
        [parameter(Mandatory=$true)]
        [string] $Database,
        [parameter(Mandatory=$true)]
        [string] $Query,
        [string[]] $args
    )

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$SCCMServer;database=$Database;Integrated Security=True;"
    $SqlConnection.Open()

    if ( $SqlConnection.State -ne 'Open' ) {
        throw "unable to open database connection"
    }

    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
    $SQLCommand.Connection = $SqlConnection
    $SQLCommand.CommandText = ( $Query -f $args )

    $SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SQLCommand

    $SQLDataset = New-Object System.Data.DataSet
    $SqlAdapter.fill($SQLDataset) | out-null

    $SQLDataset.Tables[0] | Write-Output
    $SqlConnection.close()
}

