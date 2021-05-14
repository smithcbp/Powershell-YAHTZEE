#requires -version 5
<#
.SYNOPSIS
  Enjoy an exciting game of Yahtzee!
.DESCRIPTION
  Kicks off a game of Yahtzee completely in the console. Currently single player only.
.NOTES
  Version:        1.0
  Author:         Chris Smith https://github.com/smithcbp
  Creation Date:  5/14/2020
  Purpose/Change: Initial script development
  
.EXAMPLE
  Just run YahtzeeGame.ps1 and have fun :)
#>

#Console Menu Selection Function
Function Read-Choice {
  [cmdletbinding()]
  param(
    [parameter(
      Mandatory = $true,
      ValueFromPipeline = $true)]
    $Options,
    [string]$Property,
    [string]$Prompt = "Select you score"
  )
  Begin {
    $ObjectArray = @()
    $ChoiceArray = @()
  }
  Process {
    #Gather up options
    if ($Property -and $Property -notin ($Options[0] | Get-Member | Select-Object -ExpandProperty name)) {
      Throw "Property `"$Property`" is not an attribute of choice $($Options[0])"
    }
    $Options | ForEach-Object {
      $ObjectArray += $_
      if ($Property) {
        $ChoiceArray += $_.$Property
      }
      else {
        $ChoiceArray += $_
      }
    }
  }
  End {
    for ($i = 0; $i -lt $ChoiceArray.Count; $i++) {
      #Show options
      #Write-Host "  " -NoNewline
      #Write-Host ($i + 1) -NoNewline -ForegroundColor Green -BackgroundColor Black
      #Write-Host ". $($ChoiceArray[$i])" 
    }
    Do {
      $Answer = Read-Host -Prompt $Prompt
      if ($Answer -in 1..($ChoiceArray.count)) {
        $Chosen = $ObjectArray[$Answer - 1]
      }
      if (!$Chosen) { 
        Write-Host "Invalid choice '$Answer'.  Please try again or press Ctrl+C to quit." -ForegroundColor Yellow
      }
      else {
        $Chosen
      }
    } While (!$Chosen)
  } 
}

#Dice Roll Function
function Invoke-DiceRoll {
  Param([int]$numberofdice)
  $dicearray = 1..$($numberofdice) 
  foreach ($number in $dicearray) { 1..6 | Get-Random }
}

#Array of Score Names
$ScoreNameArray = @(
  'Ones'
  'Twos'
  'Threes'
  'Fours'
  'Fives'
  'Sixes'
  'ThreeofaKind'
  'FourofaKind'
  'FullHouse'
  'SmStraight'
  'LgStraight'
  'Yahtzee'
  'Chance'
)

#Set TurnNumber Variable to be incremented
$TurnNumber = 1

#Create Scoreboard Object and populate with scorename properties
$ScoreboardObject = New-Object -TypeName psobject
foreach ($ScoreName in $ScoreNameArray) { $ScoreboardObject | Add-Member -MemberType NoteProperty -name $ScoreName -Value '' }

#Kicks off 1 round of Yahtzee
function Invoke-YahtzeeTurn {

  #Set up incrementing variables
  $NumberOfRolls = 1
  $i = 0
  $RollResult = 1..5

  #Build Die Objects
  foreach ($Die in $RollResult) {
    $i++
    $Die | Add-Member -MemberType NoteProperty -name "DicePosition" -Value ($i) -Force
    #$Die | Add-Member -MemberType NoteProperty -name "DicePosition" -Value ([char](64 + $i)) -Force  #Select die with letter instead of number
    $Die | Add-Member -MemberType NoteProperty -name "Held" -Value " " -Force
    $Die | Add-Member -MemberType NoteProperty -name "Value" -Value (Invoke-DiceRoll -numberofdice 1) -Force
    #$Die | Add-Member -MemberType NoteProperty -name "Icon" -Value (Invoke-DiceRoll -numberofdice 1) -Force #might be used to add 
  }

  #Roll only 2 more times after initial
  $RollResult = While ($NumberOfRolls -le 2) {
    #Fresh Clean Console
    Clear-Host
    #Write TurnNumbers and Scoreboard to console
    Write-Host -ForegroundColor Yellow "Turn $TurnNumber of 13"
    Write-Host "Scoreboard:"
    Write-Host ($ScoreboardObject | Select-Object Ones, Twos, Threes, Fours, Fives, Sixes | Format-Table | Out-String )
    Write-Host ($ScoreboardObject | Select-Object ThreeofaKind, FourofaKind, FullHouse, SmStraight, LgStraight, Yahtzee, Chance | Format-Table | Out-String )

    #Clear held property and write die postion and value to console
    Write-Host "Your die:"
    foreach ($Die in $RollResult) { 
      $Die.Held = ' '
      Write-Host -ForegroundColor Green "$($Die.DicePosition).) $($Die.value)" 
    }
    
    #Prompt for die selection
    $HoldAnswer = Read-Host "Choose the die you would like to hold (i.e. 123,42,12345)"
    $HoldAnswer = $HoldAnswer.ToCharArray()

    #Modify die object with held property
    foreach ($Die in $RollResult) {
      foreach ($Answer in $HoldAnswer) {
        if ($($Die.DicePosition) -match $Answer) {
          $Die.Held = "Hold"
        }  
      }
      
      #Indicate held die for 1 sec.
      Write-Host "$($Die.DicePosition). $($Die.value) $($Die.Held)"
      
      #Reroll non-held die
      if ($($Die.Held) -notlike "Hold") {
        $Die.Value = Invoke-DiceRoll -numberofdice 1
        $Die.Held = " "
        $Die.Value
      }
    }

    #Pause showing held result
    Start-Sleep -Seconds 1
    
    #Check if all 5 die held and end turn
    if ($($HoldAnswer.count) -eq 5) { 
      $NumberOfRolls = 2
    }

    #Increment number of rolls
    $NumberOfRolls++

    #Output final roll result after 3 rolls
    if ($NumberOfRolls -ge 3) { $RollResult }
  }

  #Fresh clean console
  Clear-Host
  
  #Write scoreboard to console
  Write-Host "Scoreboard:"
  Write-Host ($ScoreboardObject | Select-Object Ones, Twos, Threes, Fours, Fives, Sixes | Format-Table | Out-String )
  Write-Host ($ScoreboardObject | Select-Object ThreeofaKind, FourofaKind, FullHouse, SmStraight, LgStraight, Yahtzee, Chance | Format-Table | Out-String )

  #Convert roll result to array of values
  $RollResult = $RollResult.value

  #Create Scoring Table Object, a temporary scoreboard for choosing which score to take
  $SelectScoringTableObject = New-Object -TypeName PSObject
  
  #Make all score values 0
  foreach ($ScoreName in $ScoreNameArray) { $SelectScoringTableObject | Add-Member -MemberType NoteProperty -name $ScoreName -Value '0' }

  #Top section score calculating
  $SelectScoringTableObject.Ones = ($RollResult -match '1' | Measure-Object -sum).sum
  $SelectScoringTableObject.Twos = ($RollResult -match '2' | Measure-Object -sum).sum
  $SelectScoringTableObject.Threes = ($RollResult -match '3' | Measure-Object -sum).sum
  $SelectScoringTableObject.Fours = ($RollResult -match '4' | Measure-Object -sum).sum
  $SelectScoringTableObject.Fives = ($RollResult -match '5' | Measure-Object -sum).sum
  $SelectScoringTableObject.Sixes = ($RollResult -match '6' | Measure-Object -sum).sum

  #Bottom section score calculating
  $SelectScoringTableObject.ThreeofaKind = if ((($RollResult | Group-Object) | Select-Object -expand count) -ge 3) { $RollResult | Measure-Object -sum | Select-Object -ExpandProperty sum }
  else { '0' }
  $SelectScoringTableObject.FourofaKind = if (((($RollResult | Group-Object) | Select-Object -expand count) -ge 4)) { $RollResult | Measure-Object -sum | Select-Object -ExpandProperty sum }
  else { '0' }
  $SelectScoringTableObject.FullHouse = if (((($RollResult | Group-Object) | Select-Object count) -match '3') -and ((($RollResult | Group-Object) | Select-Object count) -match '2')) { '35' }
  else { '0' }
  $SelectScoringTableObject.SmStraight = if ((( -join ($RollResult | Sort-Object -u) -match "1234|2345|3456|12345|23456")) -eq $true ) { '30' }
  else { '0' }
  $SelectScoringTableObject.LgStraight = if ((( -join ($RollResult | Sort-Object -u) -match "12345|23456")) -eq $true ) { '40' }
  else { '0' }
  $SelectScoringTableObject.Yahtzee = if ((($RollResult | Group-Object) | Select-Object count) -match '5') { '50' }
  else { '0' }
  $SelectScoringTableObject.Chance = $RollResult | Measure-Object -sum | Select-Object -ExpandProperty sum

  #Build Score Selection Menu
  $ScoreMenu = $SelectScoringTableObject.psobject.Properties | Select-Object Name, Value 
  $ScoreMenu = foreach ($item in $ScoreMenu) {
    if ($($ScoreboardObject.$($item.name)) -like '') {
      $item
    }             
  }

  #Present Score Selection Menu
  $c = 0
  Write-Host "Final Roll: $($RollResult -join ',')"
  Write-Host -ForegroundColor Yellow "Score Choices:"
  foreach ($item in $ScoreMenu) {
    $c++
    Write-Host "$c.) $($item.value) $($item.name) "
  }
    
  #Read menu selection, output selected score object.
  $ScoreChoice = Read-Choice -Options $ScoreMenu.name 
  $SelectedScore = $ScoreMenu | Where-Object name -Like $ScoreChoice
  $SelectedScore
}

#Invoke Yahtzee round for each scorable item. Increment turn number
foreach ($item in $ScoreNameArray) {
  $TurnResult = Invoke-YahtzeeTurn 
  $ScoreboardObject.$($TurnResult.Name) = $TurnResult.Value
  $TurnNumber++
}

#Fresh clean console
Clear-Host

#Write scoreboard to console
Write-Host "Scoreboard:"
Write-Host ($ScoreboardObject | Select-Object Ones, Twos, Threes, Fours, Fives, Sixes | Format-Table | Out-String )
Write-Host ($ScoreboardObject | Select-Object ThreeofaKind, FourofaKind, FullHouse, SmStraight, LgStraight, Yahtzee, Chance | Format-Table | Out-String )

#Sum up top scores
$TopTotalSum = $ScoreboardObject.Ones + $ScoreboardObject.Twos + $ScoreboardObject.Threes + $ScoreboardObject.Fours + $ScoreboardObject.Fives + $ScoreboardObject.Sixes

#Check for bonus score
if ($TopTotalSum -ge 63) { $TopBonus = 35 }
if ($TopTotalSum -lt 63) { $TopBonus = 0 }

#Sum up bottom scores
$BottomTotalSum = $ScoreboardObject.ThreeofaKind + $ScoreboardObject.FourofaKind + $ScoreboardObject.FullHouse + $ScoreboardObject.SmStraight + $ScoreboardObject.LgStraight + $ScoreboardObject.Yahtzee + $ScoreboardObject.Chance

#Sum up final score
$FinalTotal = $TopTotalSum + $BottomTotalSum

#Write Final Results to Console
Write-Host "Top Total: $TopTotalSum"
Write-Host "Top Bonus Total: $TopBonus"
Write-Host "Bottom Total: $BottomTotalSum"
Write-Host "Total Score: $FinalTotal"
Write-Host "Good Job.... :)"

Pause
