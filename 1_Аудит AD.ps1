$Computers = (Get-ADComputer -Filter * | Measure-Object).Count
$Workstation = (Get-ADComputer -Filter { OperatingSystem -notlike "*Server*"} | Measure-Object).Count
$Servers = (Get-ADComputer -Filter { OperatingSystem -like "*Server*"} | Measure-Object).Count
$Users = (Get-ADUser -Filter * | Measure-Object).Count
$Groups = (Get-ADGroup -Filter * | Measure-Object).Count


$mainPath ="$env:USERPROFILE\Desktop\" 
$mainCount =$mainPath+"mainCount.txt"

$ComputersActive = (Get-ADComputer -Filter {Enabled -eq $true} | Measure-Object).Count
$WorkstationActive = (Get-ADComputer -Filter { OperatingSystem -notlike "*Server*" -and Enabled -eq $true } | Measure-Object).Count
$ServersActive = (Get-ADComputer -Filter { OperatingSystem -like "*Server*" -and Enabled -eq $true} | Measure-Object).Count
$UsersActive = (Get-ADUser -Filter {Enabled -eq $true} | Measure-Object).Count
$GroupsActive = (Get-ADGroup -Filter * | Measure-Object).Count

Write-Host "-----------------------Общее количество------------------------------"
"-----------------------Общее количество------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "Computers = $Computers" 
"Computers = "+$Computers| Out-File -FilePath $mainCount -Append
Write-Host "Workstation = $Workstation"
"Workstation = "+$Workstation| Out-File -FilePath $mainCount -Append
Write-Host "Servers = $Servers"
"Servers = "+$Servers| Out-File -FilePath $mainCount -Append
Write-Host "Users = $Users"
"Users = "+$Users| Out-File -FilePath $mainCount -Append
Write-Host "Groups = $Groups"
"Groups = "+$Groups| Out-File -FilePath $mainCount -Append
Write-Host "-----------------------------------------------------------------------"

Write-Host "-----------------------Количество активных------------------------------"
"-----------------------Количество активных------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "ComputersActive = $ComputersActive"
"ComputersActive = "+$ComputersActive| Out-File -FilePath $mainCount -Append
Write-Host "WorkstationActive = $WorkstationActive"
"WorkstationActive = "+$WorkstationActive| Out-File -FilePath $mainCount -Append
Write-Host "ServersActive = $ServersActive"
"ServersActive = "+$ServersActive| Out-File -FilePath $mainCount -Append
Write-Host "UsersActive = $UsersActive"
"UsersActive = "+$UsersActive| Out-File -FilePath $mainCount -Append
Write-Host "GroupsActive = $GroupsActive"
"GroupsActive = "+$GroupsActive| Out-File -FilePath $mainCount -Append
Write-Host "-----------------------------------------------------------------------"


$ADForest = (Get-ADDomain).Forest
$ADForestMode = (Get-ADForest).ForestMode
$ADDomainMode = (Get-ADDomain).DomainMode


Write-Host "---------------------Информация о домене и лесе---------------------------------"
"---------------------Информация о домене и лесе---------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "Active Directory Forest Name = $ADForest"
"Active Directory Forest Name="+$ADForest| Out-File -FilePath $mainCount -Append
Write-Host "Active Directory Forest Mode = $ADForestMode"
"Active Directory Forest Mode="+$ADForestMode| Out-File -FilePath $mainCount -Append
Write-Host "Active Directory Domain Mode = $ADDomainMode"
"Active Directory Domain Mode="+$ADDomainMode| Out-File -FilePath $mainCount -Append

Write-Host "-----------------------------------------------------------------------"

$ADVer = Get-ADObject (Get-ADRootDSE).schemaNamingContext -property objectVersion | Select-Object objectVersion
$ADNum = $ADVer -replace "@{objectVersion=","" -replace "}",""
If ($ADNum -eq '88') {$srv = 'Windows Server 2019/Windows Server 2022'}
ElseIf ($ADNum -eq '87') {$srv = 'Windows Server 2016'}
ElseIf ($ADNum -eq '69') {$srv = 'Windows Server 2012 R2'}
ElseIf ($ADNum -eq '56') {$srv = 'Windows Server 2012'}
ElseIf ($ADNum -eq '47') {$srv = 'Windows Server 2008 R2'}
ElseIf ($ADNum -eq '44') {$srv = 'Windows Server 2008'}
ElseIf ($ADNum -eq '31') {$srv = 'Windows Server 2003 R2'}
ElseIf ($ADNum -eq '30') {$srv = 'Windows Server 2003'}


#FSMO
$Forest = Get-ADForest
$SchemaMaster = $Forest.SchemaMaster
$DomainNamingMaster = $Forest.DomainNamingMaster
$Domain = Get-ADDomain
$RIDMaster = $Domain.RIDMaster
$PDCEmulator = $Domain.PDCEmulator
$InfrastructureMaster = $Domain.InfrastructureMaster

Write-Host "----------------------Информация о FSMO ролях--------------------------------"
"----------------------Информация о FSMO ролях--------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "SchemaMaster = $SchemaMaster"
"SchemaMaster="+$SchemaMaster| Out-File -FilePath $mainCount -Append
Write-Host "Domain Naming Master = $DomainNamingMaster"
"Domain Naming Master="+$DomainNamingMaster| Out-File -FilePath $mainCount -Append
Write-Host "RID Master = $RIDMaster"
"RID Master="+$RIDMaster| Out-File -FilePath $mainCount -Append
Write-Host "PDCEmulator = $PDCEmulator"
"PDCEmulator="+$PDCEmulator| Out-File -FilePath $mainCount -Append
Write-Host "Infrastructure Master = $InfrastructureMaster"
"Infrastructure Master="+$InfrastructureMaster| Out-File -FilePath $mainCount -Append
Write-Host "-----------------------------------------------------------------------"


$exportPathPE = $mainPath + "PasswordNotExpires.txt"
# Получаем пользователей, у которых пароль не истекает
$PasswordNotExpires = Get-ADuser -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} -Properties Name,Enabled,DisplayName,PasswordNeverExpires,whenCreated
# Создаем список строк для записи в файл
$outputLines = @()
# Добавляем заголовок вручную только один раз
$outputLines += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $PasswordNotExpires) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLines += $line
    $outputLines += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLines | Set-Content -Path $exportPathPE -Encoding utf8


#Проверяем пользователей у которых пароль не менялся 90 дней
$exportPathP9l = $mainPath + "Password90Left.txt"
# Определяем дату порога в 90 дней назад
$DateThrehold = (Get-Date).AddDays(-91)
# Получаем пользователей, у которых пароль не менялся 90 дней
$Password90Left = Get-AdUser -Filter {PasswordLastSet -lt $DateThrehold -and Enabled -eq $true} -Properties Name,Enabled,DisplayName,PasswordNeverExpires,PasswordLastSet,whenCreated
# Создаем список строк для записи в файл
$outputLinesP9l = @()
# Добавляем заголовок вручную только один раз
$outputLinesP9l += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"PasswordLastSet";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $Password90Left) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, PasswordLastSet, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLinesP9l += $line
    $outputLinesP9l += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLinesP9l | Set-Content -Path $exportPathP9l -Encoding utf8


#Пользователи, которые не входили 90 дней
$exportPathL9l=$mainPath+"Logon90Left.txt"
# Определяем дату порога в 90 дней назад
$DateThrehold = (Get-Date).AddDays(-91)
# Получаем пользователей, которые не входили в систему 90 дней
$Logon90Left = Get-AdUser -Filter {LastLogonDate -lt $DateThrehold -and Enabled -eq $true} -Properties Name,Enabled,DisplayName,PasswordNeverExpires,PasswordLastSet,whenCreated
# Создаем список строк для записи в файл
$outputLinesL9l = @()
# Добавляем заголовок вручную только один раз
$outputLinesL9l += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"PasswordLastSet";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $Logon90Left) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, PasswordLastSet, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLinesL9l += $line
    $outputLinesL9l += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLinesL9l | Set-Content -Path $exportPathL9l -Encoding utf8


#Получаем группы по типу
$GroupSecurity = (Get-ADGroup -Filter {GroupCategory -eq "Security"} | Measure-Object).Count
$GroupSecurityGlobal = (Get-ADGroup -Filter {GroupCategory -eq "Security" -and GroupScope -eq "Global"} | Measure-Object).Count
$GroupSecurityDomainLocal = (Get-ADGroup -Filter {GroupCategory -eq "Security" -and GroupScope -eq "DomainLocal"} | Measure-Object).Count
$GroupSecurityUniversal = (Get-ADGroup -Filter {GroupCategory -eq "Security" -and GroupScope -eq "Universal"} | Measure-Object).Count
$GroupDistribution = (Get-ADGroup -Filter {GroupCategory -eq "Distribution"} | Measure-Object).Count

Write-Host "----------------------Информация о группах--------------------------------"
"----------------------Информация о группах--------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "Групп Security = $GroupSecurity"
"Групп Security="+$GroupSecurity| Out-File -FilePath $mainCount -Append
Write-Host "Групп Security Global = $GroupSecurityGlobal"
"Групп Security Global="+$GroupSecurityGlobal| Out-File -FilePath $mainCount -Append
Write-Host "Групп Security DomainLocal = $GroupSecurityDomainLocal"
"Групп Security DomainLocal="+$GroupSecurityDomainLocal| Out-File -FilePath $mainCount -Append
Write-Host "Групп Security Universal = $GroupSecurityUniversal"
"Групп Security Universal="+$GroupSecurityUniversal| Out-File -FilePath $mainCount -Append
Write-Host "Групп Distribution = $GroupDistribution"
"Групп Distribution="+$GroupDistribution| Out-File -FilePath $mainCount -Append
Write-Host "-----------------------------------------------------------------------"

#получаем группы в которых нет участников
$exportPathNG =$mainPath+"nullGroup.txt"
$nullGroup= Get-ADGroup -Filter * -Properties Members | where {-not $_.members} | Select-Object Name, DistinguishedName,description
$nullGroup | Export-Csv -Path $exportPathNG -Delimiter ';' -NoTypeInformation -Encoding utf8

Write-Host "----------------------Группы в которых нет участников--------------------------------"
$nullGroupCount = (Get-ADGroup -Filter * -Properties Members | where {-not $_.members} | Measure-Object).Count
"----------------------Группы в которых нет участников--------------------------------" | Out-File -FilePath $mainCount -Append
"Группы в которых нет участников="+$nullGroupCount | Out-File -FilePath $mainCount -Append


#Get-GPO -All | Measure-Object | Select-Object -ExpandProperty Count

#список пользователей Domain Admins
$exportPathDA = $mainPath + "DomainAdmins.txt"
# Получаем пользователей группы Domain Admins
$DomainAdmins = Get-ADGroupMember -Identity "Domain Admins" | Get-ADUser -Properties Name,Enabled,DisplayName,PasswordNeverExpires,PasswordLastSet,whenCreated
# Создаем список строк для записи в файл
$outputLinesDA = @()
# Добавляем заголовок вручную только один раз
$outputLinesDA += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"PasswordLastSet";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $DomainAdmins) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, PasswordLastSet, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLinesDA += $line
    $outputLinesDA += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLinesDA | Set-Content -Path $exportPathDA -Encoding utf8


#список пользователей Schema Admins
$exportPathSA = $mainPath + "SchemaAdmins.txt"
# Получаем пользователей группы Schema Admins
$SchemaAdmins = Get-ADGroupMember -Identity "Schema Admins" | Get-ADUser -Properties Name,Enabled,DisplayName,PasswordNeverExpires,PasswordLastSet,whenCreated
# Создаем список строк для записи в файл
$outputLinesSA = @()
# Добавляем заголовок вручную только один раз
$outputLinesSA += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"PasswordLastSet";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $SchemaAdmins) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, PasswordLastSet, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLinesSA += $line
    $outputLinesSA += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLinesSA | Set-Content -Path $exportPathSA -Encoding utf8


#список пользователей Enterprise Admins
$exportPathEA = $mainPath + "EnterpriseAdmins.txt"
# Получаем пользователей группы Enterprise Admins
$EnterpriseAdmins = Get-ADGroupMember -Identity "Enterprise Admins" | Get-ADUser -Properties Name,Enabled,DisplayName,PasswordNeverExpires,PasswordLastSet,whenCreated
# Создаем список строк для записи в файл
$outputLinesEA = @()
# Добавляем заголовок вручную только один раз
$outputLinesEA += '"Name";"Enabled";"DisplayName";"PasswordNeverExpires";"PasswordLastSet";"whenCreated"'
# Проходим по каждому пользователю и добавляем запись и пустую строку
foreach ($user in $EnterpriseAdmins) {
    $line = $user | Select-Object Name, Enabled, DisplayName, PasswordNeverExpires, PasswordLastSet, whenCreated | ConvertTo-Csv -Delimiter ';' -NoTypeInformation | Select-Object -Skip 1
    $outputLinesEA += $line
    $outputLinesEA += "" # добавляем пустую строку
}
# Записываем строки в файл
$outputLinesEA | Set-Content -Path $exportPathEA -Encoding utf8


#Получить список контроллеров домена
$exportPathDC=$mainPath+"DomainController.txt"
$DomainController = Get-ADDomainController -Filter * | Select-Object HostName,IPv4Address,OperatingSystem,Enabled,Domain,Forest
$DomainController | Export-Csv -Path $exportPathDC -Delimiter ';' -NoTypeInformation -Encoding utf8

#Получить список сайтов
#Get-ADSite

#список рабочих станций
$exportPathWA=$mainPath+"WorkStationActive.txt"
$WorkstationActive = (Get-ADComputer -Filter { OperatingSystem -notlike "*Server*" -and Enabled -eq $true } | Measure-Object).Count
$WorkstationActive | Export-Csv -Path $exportPathDA -Delimiter ';' -NoTypeInformation -Encoding utf8

#список серверов
$exportPathSA=$mainPath+"DesktopServersActive.txt"
$ServersActive = (Get-ADComputer -Filter { OperatingSystem -like "*Server*" -and Enabled -eq $true} | Measure-Object).Count
$ServersActive | Export-Csv -Path $exportPathDA -Delimiter ';' -NoTypeInformation -Encoding utf8

#список рабочих станций
$exportPathWAList=$mainPath+"WorkStationActiveList.txt"
$WorkstationActiveList = (Get-ADComputer -Filter { OperatingSystem -notlike "*Server*" -and Enabled -eq $true } -Properties * | Select-Object DNSHostName,SamAccountName,IPv4Address,OperatingSystem,Enabled,Domain,whenCreated,Description,objectSid,LockedOut)
$WorkstationActiveList | Export-Csv -Path $exportPathWAList -Delimiter ';' -NoTypeInformation -Encoding utf8

#список серверов
$exportPathSAList=$mainPath+"ServersActiveList.txt"
$ServersActiveList = (Get-ADComputer -Filter { OperatingSystem  -like "*Server*" -and Enabled -eq $true} -Properties * | Select-Object DNSHostName,SamAccountName,IPv4Address,OperatingSystem,Enabled,Domain,whenCreated,Description,objectSid,LockedOut)
$ServersActiveList | Export-Csv -Path $exportPathSAList -Delimiter ';' -NoTypeInformation -Encoding utf8


#группы в которых нет описания
$GroupDescNull = (Get-ADGroup -Filter * -Properties description |where {-not $_.Description}| Measure-Object).Count

Write-Host "----------------------Группы в которых нет описания--------------------------------"
"----------------------Группы в которых нет описания--------------------------------"| Out-File -FilePath $mainCount -Append
Write-Host "которых нет описания = $GroupDescNull"
Write-Host "-----------------------------------------------------------------------"
"Группы в которых нет описания:"+$GroupDescNull| Out-File -FilePath $mainCount -Append
#групп у которых нет описания
$exportPathDN=$mainPath+"GroupDescNullList.txt"
$GroupDescNullList=Get-ADGroup -Filter * -Properties description |where {-not $_.Description}
$GroupDescNullList | Export-Csv -Path $exportPathDN -Delimiter ';' -NoTypeInformation -Encoding utf8

# Получение информации о сайтах репликации
Write-Host "-----------------------Сайты репликации------------------------------"
$exportPathReplicationSites=$mainPath+"ReplicationSites.txt"
$ReplicationSites = Get-ADReplicationSite -Filter * | Select Name
$ReplicationSites | Export-Csv -Path $exportPathReplicationSites -Delimiter ';' -NoTypeInformation -Encoding utf8
Write-Host "Сайты репликации собраны"


# Получение информации о подсетях ad
$exportPathReplicationSubnets=$mainPath+"ReplicationSubnets.txt"
$ReplicationSubnets = Get-ADReplicationSubnet -Filter * | Select-Object Name, Site
$ReplicationSubnets | Export-Csv -Path $exportPathReplicationSubnets -Delimiter ';' -NoTypeInformation -Encoding utf8


# Получение информации о ссылках репликации
Write-Host "-----------------------Ссылки репликации------------------------------"
# Путь к файлу для сохранения данных
$exportPathReplicationConnections = $mainPath + "ReplicationConnections.txt"

# Получение информации о соединениях репликации
$ReplicationConnections = Get-ADReplicationConnection -Filter * | 
    Select-Object Name, ReplicateFromDirectoryServer, ReplicateToDirectoryServer, AutoGenerated, InterSiteTransportProtocol, 
                  @{Name='ReplicatedNamingContexts';Expression={[string]::Join(";", $_.ReplicatedNamingContexts)}}, 
                  @{Name='ReplicationSchedule';Expression={if ($_.ReplicationSchedule) { $_.ReplicationSchedule.ToString() } else { "Not Scheduled" }}}

# Запись данных в структурированном виде в текстовый файл
$ReplicationConnections | ForEach-Object {
    $output = @"
--------------------------
Имя соединения репликации: $($_.DistinguishedName)
Сервер, с которого происходит репликация: $($_.ReplicateFromDirectoryServer)
Сервер, на который реплицируются данные: $($_.ReplicateToDirectoryServer)
Соединение сгенерировано автоматически: $($_.AutoGenerated)
"@
    $output | Out-File -FilePath $exportPathReplicationConnections -Append -Encoding utf8
}

Write-Host "Информация о соединениях репликации собрана в $exportPathReplicationConnections"

